#!/usr/bin/env bash

SRC="pics/originals"
OUT="pics/meta/photos.json"

mkdir -p "$(dirname "$OUT")"
shopt -s nullglob nocaseglob

# --- Collect all image files ---
FILES=("$SRC"/*.jpg "$SRC"/*.jpeg "$SRC"/*.png)
TOTAL=${#FILES[@]}

if [ $TOTAL -eq 0 ]; then
  echo "No images found in $SRC"
  exit 1
fi

echo "Processing $TOTAL images..."

# --- Initialize JSON array ---
echo "[" > pics/meta/photos_new.json
COUNT=0

for FILE in "${FILES[@]}"; do
  ((COUNT++))
  printf "\rProcessing [%d/%d]: %s ..." "$COUNT" "$TOTAL" "$(basename "$FILE")"
  # flush output immediately
  sleep 0.01

  # Extract metadata for this single file
  METADATA=$(exiftool -j \
    -FileName -DateTimeOriginal -Make -Model -ExposureTime -FNumber -FocalLength -ISO \
    "$FILE" 2>/dev/null \
    | jq '.[0] | {
        filename: .FileName,
        date: .DateTimeOriginal,
        camera: ((.Make // "") + " " + (.Model // "")) | gsub("^\\s+|\\s+$"; ""),
        exposure: {
          shutter: .ExposureTime,
          aperture: .FNumber,
          focal_length: .FocalLength,
          iso: .ISO
        },
        description: ""
      }'
  )

  # Add comma if not first entry
  if [ $COUNT -gt 1 ]; then
    echo "," >> pics/meta/photos_new.json
  fi

  # Append metadata
  echo "$METADATA" >> pics/meta/photos_new.json
done

# Finish JSON array
echo "]" >> pics/meta/photos_new.json

# Add final line break for clarity
echo

# --- Merge with old metadata ---
if [[ -f "$OUT" ]]; then
  jq --slurpfile new pics/meta/photos_new.json --slurpfile old "$OUT" '
    $new[0] | map(
      . as $n |
      ($old[0][] | select(.filename == $n.filename) | first) as $o |
      $n + { description: ($o.description // "") }
    )
  ' > "$OUT"
else
  mv pics/meta/photos_new.json "$OUT"
fi

rm -f pics/meta/photos_new.json

echo "Metadata updated. Preserved descriptions for existing photos."
