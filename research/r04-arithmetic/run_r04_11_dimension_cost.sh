#!/usr/bin/env bash
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
probe="$here/r04_11_dimension_cost_probe.d"

failed=0
found=0

for compiler in dmd ldc2; do
    if ! command -v "$compiler" >/dev/null 2>&1; then
        continue
    fi
    found=1

    for depth in Cost1 Cost2 Cost4 Cost7; do
        for mode in NativeCost StructuralCost; do
            out="/tmp/r04_11_cost_${compiler}_${depth}_${mode}.o"
            timefile="/tmp/r04_11_cost_${compiler}_${depth}_${mode}.time"

            echo "=== $compiler $depth $mode ==="
            if [[ "$compiler" == "ldc2" ]]; then
                version_args=("--d-version=$depth" "--d-version=$mode")
            else
                version_args=("-version=$depth" "-version=$mode")
            fi

            if ! /usr/bin/time -f 'elapsed=%e user=%U sys=%S maxrss_kb=%M' \
                -o "$timefile" \
                "$compiler" -c "$probe" \
                "${version_args[@]}" \
                -of="$out"
            then
                failed=1
                continue
            fi
            cat "$timefile"
            rm -f "$out"
        done
    done
done

if [[ "$found" -eq 0 ]]; then
    echo "ERROR: neither dmd nor ldc2 found" >&2
    exit 2
fi

exit "$failed"
