with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    content = f.read()

# Find flutter: section and add uses-material-design: true
old = "flutter:\n"
# Check what comes after flutter:
idx = content.index("flutter:\n")
after = content[idx:]
print("Current flutter section:")
for line in after.split('\n')[:10]:
    print(f"  |{line}|")

# Add uses-material-design: true right after flutter:
if 'uses-material-design: true' not in content:
    content = content.replace("flutter:\n", "flutter:\n  uses-material-design: true\n\n  assets:\n    - assets/\n", 1)

with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(content)
print("\nFixed! Showing flutter section:")
with open('pubspec.yaml', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if 'flutter' in line.lower() or 'material' in line or 'assets' in line:
        print(f'{i+1}: {line}', end='')
