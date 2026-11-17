def check_file(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        text = f.read()

    clean = []
    i = 0
    n = len(text)
    while i < n:
        if text[i:i+2] == '//':
            j = text.find('\n', i)
            if j == -1: break
            i = j + 1
        elif text[i:i+2] == '/*':
            j = text.find('*/', i+2)
            if j == -1: break
            i = j + 2
        elif text[i:i+3] in ("'''", '"""'):
            q = text[i:i+3]
            j = text.find(q, i+3)
            if j == -1: break
            i = j + 3
        elif text[i] in ('"', "'"):
            q = text[i]
            i += 1
            while i < n and text[i] != q:
                if text[i] == '\\':
                    i += 1
                i += 1
            i += 1
        else:
            clean.append(text[i])
            i += 1

    clean_str = ''.join(clean)
    co = clean_str.count('{')
    cc = clean_str.count('}')
    ro = clean_str.count('(')
    rc = clean_str.count(')')
    so = clean_str.count('[')
    sc = clean_str.count(']')

    print(f"File: {filename}")
    print(f"  Curly:  open={co}, close={cc}, diff={co - cc}")
    print(f"  Round:  open={ro}, close={rc}, diff={ro - rc}")
    print(f"  Square: open={so}, close={sc}, diff={so - sc}")

print("Checking upstream original:")
check_file('dist/upstream_desktop_home_page.dart')
print("\nChecking patched:")
check_file('dist/patched_desktop_home_page.dart')
