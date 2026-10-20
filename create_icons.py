import os
from PIL import Image

src_img = r"C:\Users\DELL\.gemini\antigravity-ide\brain\ee747f62-35ec-4bbc-ab95-e6eccb683713\auraplayer_icon_1792509133224.jpg"
project_root = r"c:\Users\DELL\WebDevPractice\chrome\AuraPlayer"

img = Image.open(src_img).convert("RGBA")

# Ensure assets dir exists
assets_dir = os.path.join(project_root, "assets")
os.makedirs(assets_dir, exist_ok=True)

# 1. Save PNG
png_path = os.path.join(assets_dir, "app_icon.png")
img_resized = img.resize((512, 512), Image.Resampling.LANCZOS)
img_resized.save(png_path, format="PNG")
print(f"Saved PNG: {png_path}")

# 2. Save ICO to runner resources
ico_dest_runner = os.path.join(project_root, "windows", "runner", "resources", "app_icon.ico")
ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
img.save(ico_dest_runner, format="ICO", sizes=ico_sizes)
print(f"Saved runner ICO: {ico_dest_runner}")

# 3. Save ICO to dist portable folder
dist_portable = os.path.join(project_root, "dist", "AuraPlayer-Windows-x64")
if os.path.exists(dist_portable):
    ico_dest_dist = os.path.join(dist_portable, "app_icon.ico")
    img.save(ico_dest_dist, format="ICO", sizes=ico_sizes)
    print(f"Saved dist ICO: {ico_dest_dist}")
