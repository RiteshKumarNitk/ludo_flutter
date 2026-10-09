import os
from PIL import Image, ImageDraw

def create_logo(size, bg_color, is_adaptive=False):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    if bg_color:
        bg = Image.new('RGBA', (size, size), bg_color)
        img.paste(bg, (0, 0))
    
    draw = ImageDraw.Draw(img)
    
    # 4 tiles around a center
    # Size of tiles relative to image size
    # Let's say image size is 1000. Center is 500,500.
    # Tile size = 300x300, spacing 40.
    s = size
    ts = s * 0.32
    sp = s * 0.04
    cx, cy = s/2, s/2
    r = s * 0.08 # corner radius
    
    tiles = [
        (cx - ts - sp/2, cy - ts - sp/2, cx - sp/2, cy - sp/2, "#FF6F78"), # Top-left: Coral
        (cx + sp/2, cy - ts - sp/2, cx + ts + sp/2, cy - sp/2, "#4CD7A0"), # Top-right: Mint
        (cx - ts - sp/2, cy + sp/2, cx - sp/2, cy + ts + sp/2, "#6E9BFF"), # Bottom-left: Blue
        (cx + sp/2, cy + sp/2, cx + ts + sp/2, cy + ts + sp/2, "#F6C453"), # Bottom-right: Gold
    ]
    
    for x0, y0, x1, y1, color in tiles:
        # draw rounded rectangle
        draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=color)
        
    return img

def main():
    if not os.path.exists('android/app/src/main/res/mipmap-anydpi-v26'):
        os.makedirs('android/app/src/main/res/mipmap-anydpi-v26')
        
    # Adaptive icon background
    bg = Image.new('RGBA', (1024, 1024), '#11182B')
    bg.save('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_background.png')
        
    # Adaptive foreground (transparent bg)
    fg = create_logo(1024, None)
    # We should add some padding for adaptive icon foreground so it fits in the safe zone
    # Safe zone is 66/108 of the image size.
    padded_fg = Image.new('RGBA', (1024, 1024), (0,0,0,0))
    # Resize fg to 600x600 and paste in center
    small_fg = create_logo(600, None)
    padded_fg.paste(small_fg, (212, 212), small_fg)
    padded_fg.save('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png')
    
    # Adaptive icon XML
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
    with open('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml', 'w') as f:
        f.write(xml)

    # Legacy icons
    sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    for dpi, size in sizes.items():
        path = f'android/app/src/main/res/mipmap-{dpi}'
        if not os.path.exists(path):
            os.makedirs(path)
        icon = create_logo(size, '#11182B')
        icon.save(f'{path}/ic_launcher.png')
        
    # Check if web directory exists for favicon
    if os.path.exists('web'):
        fav192 = create_logo(192, None)
        fav192.save('web/favicon.png')
        fav512 = create_logo(512, None)
        fav512.save('web/icons/Icon-192.png')
        fav512.save('web/icons/Icon-512.png')

    # Create assets for in-app just in case
    if not os.path.exists('assets/images'):
        os.makedirs('assets/images')
    logo = create_logo(512, None)
    logo.save('assets/images/khelora_logo.png')

if __name__ == '__main__':
    main()
