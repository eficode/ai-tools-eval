#!/usr/bin/env python3
import re
import sys

def fix_var_syntax(content):
    """Fix VAR syntax for keyword calls"""
    lines = content.split('\n')
    fixed_lines = []
    
    for line in lines:
        # Skip if line doesn't contain VAR
        if 'VAR    ' not in line:
            fixed_lines.append(line)
            continue
            
        # Check if it's a VAR with keyword call
        keyword_patterns = [
            r'VAR\s+(\$\{[^}]+\})\s+(Get [A-Z])',
            r'VAR\s+(\$\{[^}]+\})\s+(Evaluate\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(Set Variable\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(GET On Session\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(POST On Session\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(PUT On Session\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(DELETE On Session\s)',
            r'VAR\s+(\$\{[^}]+\})\s+(Create List)',
            r'VAR\s+(\@\{[^}]+\})\s+(Get [A-Z])',
            r'VAR\s+(\@\{[^}]+\})\s+(Create List)',
        ]
        
        matched = False
        for pattern in keyword_patterns:
            match = re.search(pattern, line)
            if match:
                indent = len(line) - len(line.lstrip())
                var = match.group(1)
                rest = line[match.end(1):].lstrip()
                fixed_line = ' ' * indent + var + '=    ' + rest
                fixed_lines.append(fixed_line)
                matched = True
                break
        
        if not matched:
            fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: fix_var_syntax.py <file>")
        sys.exit(1)
    
    filename = sys.argv[1]
    with open(filename, 'r') as f:
        content = f.read()
    
    fixed_content = fix_var_syntax(content)
    
    with open(filename, 'w') as f:
        f.write(fixed_content)
    
    print(f"Fixed {filename}")
