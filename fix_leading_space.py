#!/usr/bin/env python3
"""Fix leading spaces in body strings after triple quotes."""
import re

with open('lib/data/rules_data.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace "body: ''' " with "body: '''" (remove leading space after triple quote)
content = re.sub(r"body: ''' ", "body: '''", content)

with open('lib/data/rules_data.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed leading spaces")
