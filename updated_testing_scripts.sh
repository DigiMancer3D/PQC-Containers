#!/bin/bash
# updated_testing_scripts.sh for pah_wrap_improved.py v2.9.1-vanity-spx-qec
#
# === IMPORTANT NOTES ===
# - Vanity + SPX-QEC features are NEW in v2.9.1
#   Use --vanity          → uses default prefix "3Dx9"
#   Use --vanity-prefix "YourPrefix"  (e.g. "PQC_", "3Dx9", "MyBrand")
#   Add --spx-qec         → forces SPX-QEC token compression (on by default with --vanity)
#
# - A .vanity sidecar file is automatically created next to .pqcasset files
#   when --vanity or --vanity-prefix is used. It contains a short, human-readable,
#   cryptographically-bound compressed hash-graph fragment.
#
# - Standalone vanity mode (no wrapping): just run with --vanity on any file.
#   Great for generating public display fragments without touching the original data.
#
# - cleanup of source_archives is now DEFAULT. Use --keep-archives to keep them for inspection.
# - --keep-source now properly COPYs (leaves originals) and disables shred.
# - Password flows REQUIRE 'pip install cryptography'
#
# Rebuild pah binary after editing pah/pah.c (hybrid add-to-container):
#   cd pah && gcc -o pah pah.c -loqs -lm   # adjust flags for your liboqs install

set -e

echo "=== Prerequisites ==="
python3 -c "import cryptography; print('cryptography OK')" || pip install cryptography

echo -e "\n=== === === ==="


echo -e "\n=== Test 1: Single File - No Password ==="
python3 pah_wrap_improved.py testfile.txt --algorithm hybrid --output-dir output
python3 pah_wrap_improved.py test_nopass/testfile.txt.pqcasset --extract --output-dir output
echo "Check unique naming if collision (rare): ls output/test_nopass/"

echo -e "\n=== === === ==="


echo -e "\n=== Test 2: Single File - With Password (3 retries, now with per-asset random salt + strong KDF) ==="
python3 pah_wrap_improved.py V_75678e451015dc8e225add1c1d2ca5fa.mp4 --password "Pass123" --algorithm sphincs --output-dir output
python3 pah_wrap_improved.py test_withpass/V_75678e451015dc8e225add1c1d2ca5fa.mp4.pqcasset --extract --output-dir output

echo -e "\n=== === === ==="


echo -e "\n=== Test 3: Container - NO Password (sources moved+shredded by default, no archive left) ==="
rm -rf output/roundtrip_nopass
mkdir -p output/roundtrip_nopass && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/roundtrip_nopass/
python3 pah_wrap_improved.py output/roundtrip_nopass --container --name roundtrip_nopass --output-dir output/roundtrip_nopass
echo "After wrap (default cleanup): ls output/roundtrip_nopass/ ; ls roundtrip_nopass/source_archives/ || echo 'No archives left (good)'"
python3 pah_wrap_improved.py output/roundtrip_nopass/roundtrip_nopass.pqcasset --extract --output-dir output/roundtrip_nopass

echo -e "\n=== === === ==="


echo -e "\n=== Test 4: Container - WITH Password + explicit --keep-archives (for inspection) ==="
rm -rf output/roundtrip_withpass
mkdir -p output/roundtrip_withpass && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/roundtrip_withpass/
python3 pah_wrap_improved.py output/roundtrip_withpass --container --name roundtrip_withpass --password "Pass123" --output-dir output/roundtrip_withpass --keep-archives
echo "Archives kept for check: ls output/roundtrip_withpass/source_archives/"
python3 pah_wrap_improved.py output/roundtrip_withpass/roundtrip_withpass.pqcasset --extract --output-dir output/roundtrip_withpass

echo -e "\n=== === === ==="


echo -e "\n=== Test 5: keep-source (should leave originals, no shred, no archives) ==="
rm -rf output/roundtrip_keep
mkdir output/roundtrip_keep && cp testfile.txt output/roundtrip_keep/
python3 pah_wrap_improved.py output/roundtrip_keep --container --name roundtrip_keep --keep-source --output-dir output/roundtrip_keep
ls output/roundtrip_keep/   # originals should still be there
echo "(no source_archives/ created)"

echo -e "\n=== === === ==="


echo -e "\n=== Test 6: Standalone Vanity SPX-QEC Fragment (no wrapping) ==="
rm -rf output/vanity_standalone
mkdir -p output/vanity_standalone
python3 pah_wrap_improved.py testfile.txt --vanity --output-dir output/vanity_standalone
echo "Check the generated fragment:"
ls -l output/vanity_standalone/
cat output/vanity_standalone/testfile.vanity.fragment
echo "Note: This is a short, branded, compressed hash-graph you can share publicly."

echo -e "\n=== === === ==="


echo -e "\n=== Test 7: Vanity during Single File Wrap ==="
rm -rf output/vanity_single
python3 pah_wrap_improved.py testfile.txt --algorithm hybrid --vanity-prefix "PQC_" --output-dir output/vanity_single
echo "Look for the .vanity sidecar next to the .pqcasset:"
ls -l output/vanity_single/

echo -e "\n=== === === ==="


echo -e "\n=== Test 8: Vanity during Container Creation ==="
rm -rf output/vanity_container
mkdir -p output/vanity_container && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/vanity_container/
python3 pah_wrap_improved.py vanity_container --container --name vanity_demo --vanity --output-dir output/vanity_container
echo "Container + .vanity fragment created:"
ls -l output/vanity_container/

echo -e "\n=== === === ==="


echo -e "\n=== Test 9: Custom prefix + explicit --spx-qec ==="
rm -rf vanity_custom
python3 pah_wrap_improved.py testfile.txt --vanity-prefix "MyBrand_" --spx-qec --output-dir output/vanity_custom
ls -l output/vanity_custom/
cat output/vanity_custom/testfile.vanity.fragment | head -c 120; echo "..."



echo -e "\n=== === === ==="



echo -e "\n=== OTHER COMMANDS ==="
python3 pah_wrap_improved.py output/roundtrip_withpass/roundtrip_withpass.pqcasset --list
python3 pah_wrap_improved.py output/roundtrip_withpass/roundtrip_withpass.pqcasset --verify
python3 pah_wrap_improved.py output/roundtrip_withpass/roundtrip_withpass.pqcasset --split 3 --output-prefix chunk
python3 pah_wrap_improved.py --clean-stacked


echo -e "\n=== === === ==="



echo -e "\n=== Test 10: MULTI-FILE WRAP (individual) ==="
python3 pah_wrap_improved.py testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 --output-dir output/multi_test



echo -e "\n=== === === ==="



echo -e "\n=== Test 11: Resolve & Validate a fragment ==="


echo -e "\n=== === === ==="


echo -e "\n== Test 12: Verify that a file matches the fragment ==="
python3 pah_wrap_improved.py --resolve-vanity "3Dx9d2TB2tb6T..." \
    --verify-file testfile.txt

echo -e "\n=== === === ==="


echo -e "\n=== Test 13: Unlock a password-protected PQC asset using the vanity fragment ==="
python3 pah_wrap_improved.py --resolve-vanity "3Dx9d2TB2tb6T..." \
    --pqcasset testfile.txt.pqcasset \
    --password "Pass123" \
    --output-dir unlocked/

echo -e "\n=== === === ==="


echo -e "\n=== Test 14: Simple Retrieve ==="
python3 pah_wrap_improved.py --resolve-vanity "3Dx9d2TB2tb6T..." \
    --pqcasset testfile.txt.pqcasset \
    --password "Pass123" \
    --retrieve

echo -e "\n=== === === ==="


echo -e "\n=== Test 15: Full Retrieved ==="
python3 pah_wrap_improved.py --resolve-vanity "3Dx9d2TB2tb6T..." \
    --pqcasset testfile.txt.pqcasset \
    --password "Pass123" \
    --retrieve \
    --output-dir ./retrieved/


echo -e "\n=== === === ==="


echo -e "\n=== Test 16: Smart Mode ==="
python3 pah_wrap_improved.py --resolve-vanity "3Dx9d2TB2tb6T..." \
    --password "Pass123" \
    --retrieve

echo -e "\n=== === === ==="


echo -e "\n=== Test 17: Vanity-as-Password ==="
python3 pah_wrap_improved.py testfile.txt.pqcasset --extract --password "3Dx9d2TB2tb6T..."


echo -e "\n=== === === ==="

------------------------------
------------------------------
------------------------------
------------------------------
------------------------------
------------------------------
#!/bin/bash
# updated_testing_scripts.sh for pah_wrap_improved.py v2.9.2-bugfix-vanity
#
# === IMPORTANT NOTES ===
# - All vanity features now work correctly with --vanity-prefix + --algorithm
# - Checksum has legacy fallback (old fragments still validate)
# - Use freshly generated .vanity.fragment files for resolve tests
# - Default output is now ./output/

set -e

echo "=== Prerequisites ==="
python3 -c "import cryptography; print('cryptography OK')" || pip install cryptography

echo -e "\n=== === === ==="

# ==================== BASIC TESTS ====================

echo -e "\n=== Test 1: Single File - No Password ==="
python3 pah_wrap_improved.py testfile.txt --algorithm hybrid --output-dir output
python3 pah_wrap_improved.py output/testfile.txt_*.pqcasset --extract --output-dir output/extracted_test1

echo -e "\n=== Test 2: Single File - With Password ==="
python3 pah_wrap_improved.py V_75678e451015dc8e225add1c1d2ca5fa.mp4 --password "Pass123" --algorithm sphincs --output-dir output
python3 pah_wrap_improved.py output/V_75678e451015dc8e225add1c1d2ca5fa.mp4_*.pqcasset --extract --output-dir output/extracted_test2 --password "Pass123"

echo -e "\n=== Test 3: Container - NO Password ==="
rm -rf output/roundtrip_nopass
mkdir -p output/roundtrip_nopass && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/roundtrip_nopass/
python3 pah_wrap_improved.py output/roundtrip_nopass --container --name roundtrip_nopass --output-dir output/roundtrip_nopass
python3 pah_wrap_improved.py output/roundtrip_nopass/roundtrip_nopass.pqcasset --extract --output-dir output/roundtrip_nopass/extracted

echo -e "\n=== Test 4: Container - WITH Password + --keep-archives ==="
rm -rf output/roundtrip_withpass
mkdir -p output/roundtrip_withpass && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/roundtrip_withpass/
python3 pah_wrap_improved.py output/roundtrip_withpass --container --name roundtrip_withpass --password "Pass123" --output-dir output/roundtrip_withpass --keep-archives
python3 pah_wrap_improved.py output/roundtrip_withpass/roundtrip_withpass.pqcasset --extract --output-dir output/roundtrip_withpass/extracted --password "Pass123"

echo -e "\n=== Test 5: keep-source ==="
rm -rf output/roundtrip_keep
mkdir output/roundtrip_keep && cp testfile.txt output/roundtrip_keep/
python3 pah_wrap_improved.py output/roundtrip_keep --container --name roundtrip_keep --keep-source --output-dir output/roundtrip_keep

echo -e "\n=== Test 6: Standalone Vanity ==="
rm -rf output/vanity_standalone
mkdir -p output/vanity_standalone
python3 pah_wrap_improved.py testfile.txt --vanity --output-dir output/vanity_standalone
cat output/vanity_standalone/testfile.vanity.fragment

echo -e "\n=== Test 7: Vanity during Single File Wrap ==="
rm -rf output/vanity_single
python3 pah_wrap_improved.py testfile.txt --algorithm hybrid --vanity-prefix "PQC_" --output-dir output/vanity_single

echo -e "\n=== Test 8: Vanity during Container Creation ==="
rm -rf output/vanity_container
mkdir -p output/vanity_container && cp testfile.txt V_75678e451015dc8e225add1c1d2ca5fa.mp4 output/vanity_container/
python3 pah_wrap_improved.py output/vanity_container --container --name vanity_demo --vanity --output-dir output/vanity_container

echo -e "\n=== Test 9: Custom prefix + --spx-qec ==="
rm -rf output/vanity_custom
python3 pah_wrap_improved.py testfile.txt --vanity-prefix "MyBrand_" --spx-qec --output-dir output/vanity_custom

# ==================== RESOLVE + RETRIEVE TESTS (Updated) ====================

echo -e "\n=== Test 11: Resolve only (no retrieve) ==="
# Use a freshly generated fragment from Test 6 or 7
FRAG_FILE="output/vanity_standalone/testfile.vanity.fragment"
if [ -f "$FRAG_FILE" ]; then
    FRAG=$(cat "$FRAG_FILE" | head -n 1)
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG"
fi

echo -e "\n=== Test 12: Verify file matches fragment ==="
if [ -f "$FRAG_FILE" ]; then
    FRAG=$(cat "$FRAG_FILE" | head -n 1)
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG" --verify-file testfile.txt
fi

echo -e "\n=== Test 13-17: Resolve + Retrieve / Vanity-as-Password ==="
if [ -f "$FRAG_FILE" ]; then
    FRAG=$(cat "$FRAG_FILE" | head -n 1)

    echo "Test 13: Unlock with vanity fragment + password"
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG" \
        --pqcasset output/testfile.txt_*.pqcasset \
        --password "Pass123" \
        --output-dir output/unlocked/

    echo "Test 14: Simple Retrieve"
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG" \
        --pqcasset output/testfile.txt_*.pqcasset \
        --password "Pass123" \
        --retrieve

    echo "Test 15: Full Retrieved with output dir"
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG" \
        --pqcasset output/testfile.txt_*.pqcasset \
        --password "Pass123" \
        --retrieve \
        --output-dir output/retrieved/

    echo "Test 16: Smart Mode Retrieve"
    python3 pah_wrap_improved.py --resolve-vanity "$FRAG" \
        --password "Pass123" \
        --retrieve

    echo "Test 17: Vanity fragment as Password"
    python3 pah_wrap_improved.py output/testfile.txt_*.pqcasset --extract --password "$FRAG"
fi

echo -e "\n=== === === ==="
echo "All tests completed. Check the output/ directory for results."



------

# === NEW TESTS FOR v2.9.2 FEATURES ===

echo -e "\n=== New Test: --spx-op support ==="
python3 pah_wrap_improved.py testfile.txt --vanity-prefix "SPX_" --spx-qec --spx-op 1 --output-dir output/spx_op_test

echo -e "\n=== New Test: Resolve using fragment FILE (recommended) ==="
python3 pah_wrap_improved.py --resolve-vanity "$(cat output/vanity_standalone/testfile.vanity.fragment | head -n 1)" \
    --verify-file testfile.txt

echo -e "\n=== New Test: --key-file support (basic) ==="
# First generate a key family manually if needed, then:
python3 pah_wrap_improved.py testfile.txt --algorithm hybrid --key-file keygen/example.kchain --output-dir output/key_test
