#!/usr/bin/env bash

SRC="pics/originals"
GALLERY="pics/gallery"
FULL="pics/full"

mkdir -p "$GALLERY" "$FULL"

shopt -s nullglob nocaseglob

for img in "$SRC"/*.{jpg,jpeg,png}; do
  name=$(basename "$img")

  magick "$img" -auto-orient -resize 1200x -quality 82 "$GALLERY/$name"
  magick "$img" -auto-orient -resize 3000x -quality 90 "$FULL/$name"
done
