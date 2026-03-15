import sys

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = f.read()
    
    # We will just run git checkout --ours or --theirs? No, the conflict markers are already in the file and it's committed!
    # So we have to parse them out.
    
    # Conflict 1: lines 284-304
    # keep HEAD's logic + bottom's comment
    import re
    
    lines = data.split('\n')
    out = []
    i = 0
    in_conflict = False
    conflict_state = 0 # 0=none, 1=HEAD, 2=THEIRS
    head_lines = []
    theirs_lines = []
    
    while i < len(lines):
        line = lines[i]
        if line.startswith('<<<<<<< HEAD'):
            in_conflict = True
            conflict_state = 1
            head_lines = []
            theirs_lines = []
        elif line.startswith('======='):
            conflict_state = 2
        elif line.startswith('>>>>>>>'):
            # resolve
            part1 = '\n'.join(head_lines)
            part2 = '\n'.join(theirs_lines)
            
            if 'const allowedPlaces =' in part1:
                # Conflict 1: we want the logic from HEAD, but the comment from theirs
                out.extend(head_lines[:-1]) # remove '// Case-insensitive lookup'
                out.extend(theirs_lines) # add '// Case-insensitive lookup for "From" coords'
            elif 'const routeOrder = [' in part1:
                # Conflict 2: we want the logic from THEIRS
                out.extend(theirs_lines)
            else:
                out.extend(theirs_lines) # default to theirs
                
            in_conflict = False
            conflict_state = 0
        else:
            if conflict_state == 1:
                head_lines.append(line)
            elif conflict_state == 2:
                theirs_lines.append(line)
            else:
                out.append(line)
        i += 1
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out))

fix_file('lib/screens/shortest_route_screen.dart')
print('Conflicts resolved!')
