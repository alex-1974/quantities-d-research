#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
probe="$here/r04_11_probe.d"
consumer="$here/r04_11_consumer_probe.d"
negative="$here/r04_11_negative_no_relation.d"
conflict="$here/r04_11_negative_conflict.d"
two_foreign="$here/r04_11_two_foreign_specs.d"
third_customization="$here/r04_11_third_customization_probe.d"
relation_api="$here/r04_11_relation_api_probe.d"
integral_rescale="$here/r04_11_integral_rescale_probe.d"
scaled_mul_rep="$here/r04_11_scaled_mul_rep_probe.d"
dimension_models="$here/r04_11_dimension_models_probe.d"
open_canonicalization="$here/r04_11_open_canonicalization_probe.d"
structural_dimension="$here/r04_11_structural_dimension_probe.d"
dimension_key="$here/r04_11_dimension_key_probe.d"
canonical_algebra="$here/r04_11_canonical_dimension_algebra_probe.d"

compilers=()
command -v dmd >/dev/null 2>&1 && compilers+=(dmd)
if command -v ldc2 >/dev/null 2>&1; then
    compilers+=(ldc2)
elif command -v ldc >/dev/null 2>&1; then
    compilers+=(ldc)
fi

if (("${#compilers[@]}" == 0)); then
    echo "ERROR: neither dmd nor ldc2/ldc found" >&2
    exit 2
fi

failed=0
for compiler in "${compilers[@]}"; do
    echo "=== $compiler: positive core probe ==="
    if ! "$compiler" -c "$probe" -of=/tmp/r04_11_probe_${compiler}.o; then
        failed=1
    fi

    echo "=== $compiler: external consumer probe ==="
    if ! "$compiler" -c "$consumer" "$probe" -I"$here" -of=/tmp/r04_11_consumer_${compiler}.o; then
        failed=1
    fi

    echo "=== $compiler: dimension representation models ==="
    if ! "$compiler" -c "$dimension_models" -I"$here" -of=/tmp/r04_11_dimension_models_${compiler}.o; then
        failed=1
    else
        echo "PASS: dimension representation model probe"
    fi

    echo "=== $compiler: open dimension canonicalization ==="
    if ! "$compiler" -c "$open_canonicalization" -I"$here" -of=/tmp/r04_11_open_canonicalization_${compiler}.o; then
        failed=1
    else
        echo "PASS: open dimension canonicalization probe"
    fi

    echo "=== $compiler: structural dimension semantics ==="
    if ! "$compiler" -c "$structural_dimension" -I"$here" -of=/tmp/r04_11_structural_dimension_${compiler}.o; then
        failed=1
    else
        echo "PASS: structural dimension semantics probe"
    fi

    echo "=== $compiler: dimension ordering key ==="
    key_exe="/tmp/r04_11_dimension_key_${compiler}"
    if ! "$compiler" "$dimension_key" -I"$here" -of="$key_exe"; then
        failed=1
    elif ! "$key_exe"; then
        failed=1
    fi
    rm -f "$key_exe"

    echo "=== $compiler: canonical dimension algebra ==="
    algebra_exe="/tmp/r04_11_canonical_algebra_${compiler}"
    if ! "$compiler" "$canonical_algebra" -I"$here" -of="$algebra_exe"; then
        failed=1
    elif ! "$algebra_exe"; then
        failed=1
    fi
    rm -f "$algebra_exe"

    echo "=== $compiler: scaled integral product range ==="
    if ! "$compiler" -c "$scaled_mul_rep" -I"$here" -of=/tmp/r04_11_scaled_mul_${compiler}.o; then
        failed=1
    else
        echo "PASS: combined product/rescale ResultRep classification"
    fi

    echo "=== $compiler: integral rescale classification ==="
    if ! "$compiler" -c "$integral_rescale" "$third_customization" "$probe" -I"$here" -of=/tmp/r04_11_rescale_${compiler}.o; then
        failed=1
    else
        echo "PASS: integral derived-unit rescale classification"
    fi

    echo "=== $compiler: relation API probe ==="
    if ! "$compiler" -unittest -main "$relation_api" "$third_customization" "$probe" -I"$here" -of=/tmp/r04_11_relation_api_${compiler}; then
        failed=1
    else
        /tmp/r04_11_relation_api_${compiler}
        echo "PASS: explicit and wrapper relation APIs compile and run"
    fi

    echo "=== $compiler: explicit relation-set probe ==="
    if ! "$compiler" -c "$third_customization" "$probe" -I"$here" -of=/tmp/r04_11_relations_${compiler}.o; then
        failed=1
    else
        echo "PASS: explicit relation set connects two foreign Specs"
    fi

    echo "=== $compiler: two-foreign-spec capability probe ==="
    if ! "$compiler" -c "$two_foreign" "$probe" -I"$here" -of=/tmp/r04_11_two_foreign_${compiler}.o; then
        failed=1
    else
        echo "PASS: current member hooks expose the two-foreign-spec limit"
    fi

    echo "=== $compiler: negative conflicting-hooks probe ==="
    if "$compiler" -c "$conflict" "$probe" -I"$here" -of=/tmp/r04_11_conflict_${compiler}.o >/tmp/r04_11_conflict_${compiler}.log 2>&1; then
        echo "FAIL: conflicting semantic hooks unexpectedly compiled" >&2
        failed=1
    else
        echo "PASS: conflicting semantic hooks rejected"
    fi

    echo "=== $compiler: negative no-relation probe ==="
    if "$compiler" -c "$negative" "$probe" -I"$here" -of=/tmp/r04_11_negative_${compiler}.o >/tmp/r04_11_negative_${compiler}.log 2>&1; then
        echo "FAIL: negative probe unexpectedly compiled" >&2
        failed=1
    else
        echo "PASS: missing semantic relation rejected"
    fi
done

# Preserve a useful status for normal execution, but never terminate an
# interactive parent shell when this file was accidentally sourced.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return "$failed"
fi
exit "$failed"
