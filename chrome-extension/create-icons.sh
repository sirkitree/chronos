#!/bin/bash

# Create ChronoGuard Chrome Extension Icons
# This script creates basic PNG icons for the extension

# Check if ImageMagick is available
if command -v convert >/dev/null 2>&1; then
    echo "Creating icons with ImageMagick..."
    
    # Create a simple blue circle icon with 'C' letter
    for size in 16 32 48 128; do
        convert -size ${size}x${size} xc:none \
            -fill "#007AFF" -draw "circle $((size/2)),$((size/2)) $((size/2)),0" \
            -fill white -pointsize $((size/3)) -gravity center \
            -annotate +0+0 "C" \
            "icons/icon-${size}.png"
    done
    
    echo "Icons created successfully!"
    
elif command -v sips >/dev/null 2>&1; then
    echo "ImageMagick not found. Creating placeholder icons with macOS sips..."
    
    # Create a simple colored square as placeholder
    for size in 16 32 48 128; do
        # Create a blue square using sips (macOS only)
        # This is a fallback approach
        echo "Creating ${size}x${size} placeholder icon..."
        
        # Create a temporary colored image
        cat > temp_icon.svg << EOF
<svg width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">
  <rect width="${size}" height="${size}" fill="#007AFF" rx="$((size/8))"/>
  <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="$((size/2))" 
        fill="white" text-anchor="middle" dy=".35em">C</text>
</svg>
EOF
        
        # Convert SVG to PNG (requires additional tools)
        if command -v rsvg-convert >/dev/null 2>&1; then
            rsvg-convert -w ${size} -h ${size} temp_icon.svg > "icons/icon-${size}.png"
        else
            echo "Cannot create PNG. SVG created instead."
            cp temp_icon.svg "icons/icon-${size}.svg"
        fi
    done
    
    rm -f temp_icon.svg
    
else
    echo "No image tools found. Creating simple colored squares..."
    
    # Create minimal placeholder files
    for size in 16 32 48 128; do
        # Create a simple base64 encoded 1x1 blue PNG
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > "icons/icon-${size}.png"
    done
    
    echo "Basic placeholder icons created."
fi

echo "Icon creation completed. Extension should now load in Chrome."