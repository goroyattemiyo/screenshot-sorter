with open('lib/screens/folder_select_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import 'package:flutter/foundation.dart';\n", "")
with open('lib/screens/folder_select_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
