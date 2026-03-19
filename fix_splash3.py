with open('lib/screens/splash_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "Image.asset('assets/icon.png', width: 120, height: 120),",
    """Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFF5F5), Color(0xFFFCE4EC)],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset('assets/icon.png', width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),"""
)

with open('lib/screens/splash_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
