import re, sys
with open('pubspec.yaml', encoding='utf-8') as f:
    c = f.read()
c = re.sub(r'flutter_lints: [\^]6[.]0[.]0', 'flutter_lints: ^5.0.0', c)
c = re.sub(r'build_runner: [\^]2[.]4[.]15', 'build_runner: ^2.4.13', c)
c = re.sub(r'livekit_client: [\^]2[.]5[.]0', 'livekit_client: ^2.5.1', c)
with open('pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(c)
print([l for l in c.splitlines() if any(x in l for x in ['flutter_lints','build_runner','livekit'])])
