#!/usr/bin/env python3
"""
SPX-QEC Pattern Finder
Generalized to any base 2-99 via command-line flags.
Usage examples:
    python3 find_matches.py --2
    python3 find_matches.py --binary
    python3 find_matches.py --3
    python3 find_matches.py --hex
    python3 find_matches.py --max
    python3 find_matches.py --91
"""

import os
import sys
import json
from itertools import count

# ============== FLAG MAPPING ==============
FLAG_MAP = {
    '--binary': 2, '--trinary': 3, '--hex': 6, '--octals': 8, '--dec': 10,
    '--hexdec': 16, '--duces': 21, '--cicada': 31, '--slate': 33,
    '--queens': 42, '--kings': 58, '--debil': 66, '--bet': 77,
    '--ball': 81, '--3D': 91, '--tesla': 69, '--max': 92
}
for b in range(2, 93):
    FLAG_MAP[f'--{b}'] = b

def get_base_from_args():
    for arg in sys.argv[1:]:
        if arg in FLAG_MAP:
            return FLAG_MAP[arg]
    return 2  # default binary

# ============== CORE HELPERS (work on digit lists) ==============
def int_to_digits(n, base, min_len=3):
    if n == 0:
        digs = [0]
    else:
        digs = []
        tmp = n
        while tmp > 0:
            digs.append(tmp % base)
            tmp //= base
        digs.reverse()
    while len(digs) < min_len:
        digs.insert(0, 0)
    return digs

def has_three_repeats(digs):
    for i in range(len(digs) - 2):
        if digs[i] == digs[i+1] == digs[i+2]:
            return True
    return False

def is_sublist(needle, haystack):
    if not needle:
        return True
    nlen = len(needle)
    for i in range(len(haystack) - nlen + 1):
        if haystack[i:i+nlen] == needle:
            return True
    return False

def get_parts(digs, rem_side):
    l = len(digs)
    if l < 3:
        return None, None, None
    base_size = l // 3
    rem = l % 3
    if rem_side == 'a':
        sa, sb, sc = base_size + rem, base_size, base_size
    else:
        sa, sb, sc = base_size, base_size, base_size + rem
    if sa < 1 or sb < 1 or sc < 1:
        return None, None, None
    a = digs[:sa]
    b = digs[sa:sa+sb]
    c = digs[sa+sb:sa+sb+sc]
    return a, b, c

def get_7_outputs(digs):
    parts = get_parts(digs, '-')
    if parts[0] is None:
        return None
    outs = []
    # 1 Reverse
    a, b, c = get_parts(digs, '-')
    outs.append(c + b + a)
    # 2 Back-Slip
    a, b, c = get_parts(digs, 'c')
    outs.append(c + a + b)
    # 3 Palindrome
    a, b, c = get_parts(digs, 'c')
    ab = a + b
    outs.append(ab + c + ab[::-1])
    # 4 Front-Center+
    a, b, c = get_parts(digs, 'a')
    bc = b + c
    outs.append(bc + a + bc[::-1])
    # 5 Reverse+
    outs.append(digs + digs[::-1])
    # 6 Back-Capped+
    a, b, c = get_parts(digs, 'c')
    ab = a + b
    bac = b + a + c
    outs.append(c + ab + bac)
    # 7 Center-Slip+
    a, b, c = get_parts(digs, 'c')
    ab = a + b
    outs.append(ab + c + ab[::-1] + c)
    return outs

def digits_to_display(digs, base):
    if base <= 10:
        return ''.join(str(d) for d in digs)
    elif base <= 36:
        alphabet = '0123456789abcdefghijklmnopqrstuvwxyz'
        return ''.join(alphabet[d] for d in digs)
    else:
        return '[' + ','.join(str(d) for d in digs) + ']'


def print_help():
    print("""
SPX-QEC Pattern Finder
======================

Finds the first 91 "SPX-QEC" pattern matches in any base from 2 to 99.

Usage:
    python3 find_matches.py [FLAG]

Supported textual flags (with base value):
    --binary     # 2     (default)
    --trinary    # 3
    --hex        # 6
    --octals     # 8
    --dec        # 10
    --hexdec     # 16
    --duces      # 21
    --cicada     # 31
    --slate      # 33
    --queens     # 42
    --kings      # 58
    --debil      # 66
    --bet        # 77
    --ball       # 81
    --3D         # 91
    --tesla      # 69
    --max        # 92     (new maximum)

You can also use numeric flags directly:
    --2, --3, --10, --16, ..., --92

Examples:
    python3 find_matches.py --binary
    python3 find_matches.py --3
    python3 find_matches.py --hexdec
    python3 find_matches.py --42
    python3 find_matches.py --max

Output files created in current directory:
    matches_baseN.txt
    matches_baseN.md
    matches_baseN.json

Each match shows the digit sequence + its 7 pattern outputs.
Footer contains credit instead of rejected list.
""")

# ============== MAIN ==============
def main():
    # Handle help first
    if '--help' in sys.argv or '-h' in sys.argv:
        print_help()
        sys.exit(0)

    BASE = get_base_from_args()
    if BASE < 2 or BASE > 92:
        print("Base must be between 2 and 92")
        sys.exit(1)

    print(f"SPX-QEC Pattern Finder — Base {BASE}")
    print(f"Flag used: {sys.argv[1] if len(sys.argv)>1 else 'default (binary)'}")

    accepted = []      # list of (digs_list, outputs_list_of_lists)
    rejected = []
    seen_tuples = set()   # for quick exact match using tuple(digs)

    group_size = 7
    num_groups = 13
    target = num_groups * group_size

    last_n = 0
    for n in count(0):
        last_n = n
        digs = int_to_digits(n, BASE, min_len=3)
        if has_three_repeats(digs):
            continue
        outs = get_7_outputs(digs)
        if outs is None:
            continue

        t_tuple = tuple(digs)
        # Check if this T is output of previous
        is_output_of_prev = False
        for prev_digs, prev_outs in accepted:
            for o in prev_outs:
                if tuple(o) == t_tuple:
                    is_output_of_prev = True
                    break
            if is_output_of_prev:
                break
        if is_output_of_prev:
            rejected.append(digs)
            continue

        # Check if any output equals a previous T
        output_equals_prev = False
        for o in outs:
            if tuple(o) in seen_tuples:
                output_equals_prev = True
                break
        if output_equals_prev:
            rejected.append(digs)
            continue

        # Accept
        accepted.append((digs, outs))
        seen_tuples.add(t_tuple)

        if len(accepted) >= target:
            break

    print(f"Found first {len(accepted)} matches at n={last_n} (base {BASE})")
    print(f"Total rejected during search: {len(rejected)}")

    # Groups
    groups = [accepted[i:i+group_size] for i in range(0, target, group_size)]
    group_labels = [chr(ord('b') + i) for i in range(num_groups)]

    output_dir = os.getcwd()

    # ========== TEXT ==========
    txt_path = os.path.join(output_dir, f'matches_base{BASE}.txt')
    with open(txt_path, 'w') as f:
        f.write(f"Header: SPX-QEC Patterns — Base {BASE} (flag: {sys.argv[1] if len(sys.argv)>1 else 'default'})\n")
        f.write("pos0='a', pos1='A' (reserved), pos 2-8 = 7 match objects\n")
        f.write("Reference format: e-3 etc.\n")
        f.write("Each object = digit sequence in chosen base + its 7 pattern outputs\n\n")
        f.write("Body:\n\n")
        for label, grp in zip(group_labels, groups):
            f.write(f"Array {label}:\n")
            for j, (digs, outs) in enumerate(grp):
                slot = 2 + j
                ref = f"{label}-{slot}"
                t_str = digits_to_display(digs, BASE)
                f.write(f"\t{ref}\t{t_str}\n")
                out_strs = [digits_to_display(o, BASE) for o in outs]
                f.write(f"\t\toutput-array: {', '.join(out_strs)}\n\n")
            f.write("\n")
        f.write("\n" + "="*60 + "\n")
        f.write("credit\n")
        f.write("Designed by 3D Z0M8I3D (DigiMancer3D)!  Use to determine your SPX-QEC patterns now!\n")
        f.write("="*60 + "\n")

    print(f"Written: {txt_path}")

    # ========== MARKDOWN ==========
    md_path = os.path.join(output_dir, f'matches_base{BASE}.md')
    with open(md_path, 'w') as f:
        f.write(f"# SPX-QEC Pattern Matches — Base {BASE}\n\n")
        f.write(f"**Matches found**: {len(accepted)} | **Rejected during search**: {len(rejected)} | **Last n**: {last_n}\n\n")
        for label, grp in zip(group_labels, groups):
            f.write(f"### Array `{label}` (refs `{label}-2` … `{label}-8`)\n\n")
            f.write("| Ref | T (digits) | Output-array (7 patterns) |\n")
            f.write("|-----|------------|---------------------------|\n")
            for j, (digs, outs) in enumerate(grp):
                ref = f"{label}-{2+j}"
                t_str = digits_to_display(digs, BASE)
                out_strs = [digits_to_display(o, BASE) for o in outs]
                f.write(f"| `{ref}` | `{t_str}` | {', '.join(out_strs)} |\n")
            f.write("\n")
        f.write("---\n")
        f.write("**credit**\n\n")
        f.write("Designed by 3D Z0M8I3D (DigiMancer3D)!  Use to determine your SPX-QEC patterns now!\n")

    print(f"Written: {md_path}")

    # ========== JSON ==========
    json_path = os.path.join(output_dir, f'matches_base{BASE}.json')
    header = [
        f"SPX-QEC Patterns Base {BASE}",
        "pos0=a, pos1=A reserved, pos2-8=7 matches",
        f"accepted={len(accepted)}",
        f"last_n={last_n}",
        f"flag={sys.argv[1] if len(sys.argv)>1 else 'default'}"
    ]
    body = []
    for grp in groups:
        arr = ["a", "A"] + [digits_to_display(digs, BASE) for digs, _ in grp]
        body.append(arr)
    footer = [
        "credit",
        "Designed by 3D Z0M8I3D (DigiMancer3D)!",
        "Use to determine your SPX-QEC patterns now!"
    ]
    data = [header, body, footer]
    with open(json_path, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Written: {json_path}")

    print("\n=== First 5 matches (in chosen base) ===")
    for i in range(min(5, len(accepted))):
        digs, outs = accepted[i]
        print(f"{i+1}. {digits_to_display(digs, BASE)}")
    print(f"\nDone! All files written to {output_dir}")

if __name__ == "__main__":
    main()
