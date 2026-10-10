#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly repo_url="https://github.com/yksr-melt/Meltype.git"
# 動作を確認したタグとそのコミット。別の版を試すときは MELTYPE_REF=v1.2.0 のように渡す。
readonly default_ref="v1.1.0"
readonly default_commit="f41800c86298451bb6cdd623d10a299cdb41fb7d"
readonly ref="${MELTYPE_REF:-${default_ref}}"
readonly meltype_dir="/opt/meltype"
readonly target="/usr/lib/fcitx5/meltype.so"
readonly backup_dir="${XDG_STATE_HOME:-${HOME}/.local/state}/meltype-fcitx5"

usage() {
    cat <<'EOF'
Usage: build.sh [--apply]

Without --apply, fetch the Meltype source, apply candidate-list.patch, build
the fcitx5 addon and run verify-candidate-list.cpp against /opt/meltype.
With --apply, additionally back up the current addon and install the patched
one to /usr/lib/fcitx5 with sudo. Fcitx5 is never restarted by this script.
EOF
}

apply=false
case "${1:-}" in
    "") ;;
    --apply) apply=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

for command_name in git cmake c++; do
    command -v "${command_name}" >/dev/null || {
        printf 'Missing command: %s\n' "${command_name}" >&2
        exit 1
    }
done
[[ -f "${meltype_dir}/libMeltypeNative.so" ]] || {
    printf 'Meltype is not installed in %s\n' "${meltype_dir}" >&2
    exit 1
}

work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT

git -c advice.detachedHead=false clone --quiet --depth 1 --branch "${ref}" "${repo_url}" "${work}/src"
commit="$(git -C "${work}/src" rev-parse HEAD)"
if [[ "${ref}" == "${default_ref}" && "${commit}" != "${default_commit}" ]]; then
    printf '%s now points to %s, not the reviewed %s\n' "${ref}" "${commit}" "${default_commit}" >&2
    exit 1
fi
git -C "${work}/src" apply --check "${script_dir}/candidate-list.patch" || {
    printf 'candidate-list.patch does not apply to %s; review the upstream change\n' "${ref}" >&2
    exit 1
}
git -C "${work}/src" apply "${script_dir}/candidate-list.patch"
cp "${script_dir}/verify-candidate-list.cpp" "${work}/src/linux/fcitx5/test/testmeltype.cpp"

cmake -S "${work}/src/linux/fcitx5" -B "${work}/build" \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DMELTYPE_DIR="${meltype_dir}" >/dev/null
cmake --build "${work}/build" --parallel >/dev/null

# 学習データ (~/.local/share/Meltype) に触れないよう、一時ディレクトリを HOME にして確かめる
mkdir -p "${work}/home/data"
(cd "${work}/build" &&
    HOME="${work}/home" XDG_DATA_HOME="${work}/home/data" MELTYPE_DIR="${meltype_dir}" \
        timeout 60 ./testmeltype 2>&1 | grep -E 'candidates=|failed')
printf 'Built and verified %s (%s)\n' "${ref}" "${commit}"

if ! "${apply}"; then
    printf 'Dry run: would back up %s to %s and install the patched addon.\n' "${target}" "${backup_dir}"
    exit 0
fi

mkdir -p "${backup_dir}"
if [[ -f "${target}" && ! -e "${backup_dir}/meltype.so.before-patch" ]]; then
    cp -- "${target}" "${backup_dir}/meltype.so.before-patch"
fi
sudo install -m 0755 "${work}/build/meltype.so" "${target}"
printf 'Installed %s. Restart Fcitx5 to load it: fcitx5 -rd\n' "${target}"
