#!/usr/bin/env bash

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly greetd_dir="/etc/greetd"
readonly qml_dir="${greetd_dir}/rigel-greeter"
readonly wallpaper="/usr/share/backgrounds/rigel-14/login-background.jpg"
readonly avatar="/usr/share/pixmaps/rigel-14/avatar.jpeg"

usage() {
    cat <<'EOF'
Usage: install.sh [--apply]

Without --apply, validate the source and print the planned changes.
With --apply, install root-owned copies under /etc/greetd and enable the
greetd and tty2 recovery services. The script never starts greetd or reboots.
EOF
}

apply=false
case "${1:-}" in
    "") ;;
    --apply) apply=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

for command_path in \
    /usr/bin/dbus-run-session \
    /usr/bin/greetd \
    /usr/bin/Hyprland \
    /usr/bin/hyprctl \
    /usr/bin/install \
    /usr/bin/qs \
    /usr/bin/runuser \
    /usr/bin/start-hyprland \
    /usr/bin/systemctl; do
    [[ -x "${command_path}" ]] || {
        printf 'Missing executable: %s\n' "${command_path}" >&2
        exit 1
    }
done

for source_file in config.toml hyprland.lua shell.qml; do
    [[ -r "${script_dir}/${source_file}" ]] || {
        printf 'Missing source file: %s\n' "${script_dir}/${source_file}" >&2
        exit 1
    }
done

for asset in "${wallpaper}" "${avatar}"; do
    [[ -r "${asset}" ]] || {
        printf 'Required local asset is missing or unreadable: %s\n' "${asset}" >&2
        exit 1
    }
done

printf '%s\n' \
    'Validated source files and local assets.' \
    'Planned destinations:' \
    "  ${greetd_dir}/config.toml" \
    "  ${greetd_dir}/hyprland.lua" \
    "  ${qml_dir}/shell.qml" \
    'Services to enable:' \
    '  getty@tty2.service' \
    '  greetd.service'

if [[ "${apply}" != true ]]; then
    printf '\nDry run only. Re-run with sudo bash %q --apply\n' "${script_dir}/install.sh"
    exit 0
fi

if (( EUID != 0 )); then
    printf 'The --apply operation must run as root.\n' >&2
    exit 1
fi

readonly timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
readonly backup_dir="/var/backups/rigel-14-greetd/${timestamp}"
/usr/bin/install -d -o root -g root -m 0755 "${backup_dir}"

for current_file in config.toml hyprland.lua; do
    if [[ -e "${greetd_dir}/${current_file}" ]]; then
        /usr/bin/install -o root -g root -m 0644 \
            "${greetd_dir}/${current_file}" \
            "${backup_dir}/${current_file}"
    fi
done

if [[ -e "${qml_dir}/shell.qml" ]]; then
    /usr/bin/install -o root -g root -m 0644 \
        "${qml_dir}/shell.qml" \
        "${backup_dir}/shell.qml"
fi

/usr/bin/install -d -o root -g root -m 0755 "${greetd_dir}" "${qml_dir}"
/usr/bin/install -o root -g root -m 0644 \
    "${script_dir}/config.toml" "${greetd_dir}/config.toml"
/usr/bin/install -o root -g root -m 0644 \
    "${script_dir}/hyprland.lua" "${greetd_dir}/hyprland.lua"
/usr/bin/install -o root -g root -m 0644 \
    "${script_dir}/shell.qml" "${qml_dir}/shell.qml"

/usr/bin/Hyprland --verify-config --config "${greetd_dir}/hyprland.lua"

for readable_file in \
    "${greetd_dir}/hyprland.lua" \
    "${qml_dir}/shell.qml" \
    "${wallpaper}" \
    "${avatar}"; do
    /usr/bin/runuser -u greeter -- /usr/bin/test -r "${readable_file}"
done

/usr/bin/systemctl enable getty@tty2.service greetd.service

printf '\nInstalled successfully. Backup: %s\n' "${backup_dir}"
printf '%s\n' \
    'greetd was not started and the system was not rebooted.' \
    'Review the files, then reboot when ready.'
