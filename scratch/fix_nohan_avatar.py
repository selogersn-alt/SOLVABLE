import re

file_path = r'd:\HDIGITAL\ANDROID_ANTIGRAVITY\SOLVABLE.LOGERSN\templates\components\nohan_widget.html'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern for the base64 img tag
pattern = r'<img src="data:image/png;base64,[^"]+"[^>]*>'
replacement = '<img src="{% static \'img/nohan_avatar.png\' %}" alt="NOHAN Avatar" class="w-100 h-100 object-fit-cover">'

new_content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Replacement complete.")
