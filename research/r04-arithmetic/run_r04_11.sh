#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
probe="$here/r04_11_probe.d"
consumer="$here/r04_11_consumer_probe.d"
negative="$here/r04_11_negative_no_relation.d"
conflict="$here/r04_11_negative_conflict.d"
two_foreign="$here/r04_11_two_foreign_specs.d"

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
