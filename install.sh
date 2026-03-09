#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ASSETS_DIR="$SCRIPT_DIR/plasma"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

RICE_WALLPAPER_DIR="$XDG_DATA_HOME/wallpapers/MITA"
RICE_VIDEO="$RICE_WALLPAPER_DIR/mita.mp4"
RICE_IMAGE="$RICE_WALLPAPER_DIR/mita.jpg"
RICE_VIDEO_URI="file://$RICE_VIDEO"
RICE_IMAGE_URI="file://$RICE_IMAGE"
VIDEO_WALLPAPER_PLUGIN="luisbocanegra.smart.video.wallpaper.reborn"
SDDM_THEME_ID="miside-sddm-theme"

if [[ -t 1 ]]; then
    C_RESET="$(printf '\033[0m')"
    C_CYAN="$(printf '\033[1;36m')"
    C_YELLOW="$(printf '\033[1;33m')"
    C_RED="$(printf '\033[1;31m')"
else
    C_RESET=""
    C_CYAN=""
    C_YELLOW=""
    C_RED=""
fi

info() { printf '%b\n' "${C_CYAN}[INFO]${C_RESET} $*"; }
warn() { printf '%b\n' "${C_YELLOW}[WARN]${C_RESET} $*" >&2; }
error() { printf '%b\n' "${C_RED}[ERROR]${C_RESET} $*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

is_kde_plasma() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"
    local session="${DESKTOP_SESSION:-}"
    local kde_full="${KDE_FULL_SESSION:-}"

    desktop="${desktop,,}"
    session="${session,,}"
    kde_full="${kde_full,,}"

    [[ "$desktop" == *kde* || "$desktop" == *plasma* || "$session" == *kde* || "$session" == *plasma* || "$kde_full" == "true" ]]
}

runsudo() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    elif have sudo; then
        sudo "$@"
    else
        error "Root privileges are required [x]"
        return 1
    fi
}

copyr() {
    local src="$1"
    local dst="$2"
    mkdir -p "$dst"
    if have rsync; then
        rsync -a "$src"/ "$dst"/
    else
        cp -a "$src"/. "$dst"/
    fi
}

detect_kwriteconfig() {
    local cmd
    for cmd in kwriteconfig6 kwriteconfig5 kwriteconfig; do
        if have "$cmd"; then
            printf '%s\n' "$cmd"
            return 0
        fi
    done
    return 1
}

print_title_banner() {
    cat <<'EOF'

+==============================================================+
|                       MyRice - arcxlo :3                     |
+==============================================================+

EOF
}

print_section_banner() {
    local title="$1"
    printf '\n+-------------------- %s --------------------+\n\n' "$title"
}

if ! is_kde_plasma; then
    printf '\n[Rice only for KDE Plasma, sorry 3: ]\n\n'
    exit 0
fi

KWRITECONFIG="$(detect_kwriteconfig || true)"
if [[ -z "$KWRITECONFIG" ]]; then
    error "kwriteconfig (6/5) is required but was not found."
    exit 1
fi

write_cfg() {
    local file="$1"
    local key="$2"
    local value="$3"
    shift 3

    local args=(--file "$file")
    local group
    for group in "$@"; do
        args+=(--group "$group")
    done
    args+=(--key "$key" "$value")
    "$KWRITECONFIG" "${args[@]}"
}

write_cfg_bool() {
    local file="$1"
    local key="$2"
    local value="$3"
    shift 3

    local args=(--file "$file")
    local group
    for group in "$@"; do
        args+=(--group "$group")
    done
    args+=(--key "$key" --type bool "$value")
    "$KWRITECONFIG" "${args[@]}"
}

install_assets() {
    mkdir -p \
        "$XDG_DATA_HOME/icons" \
        "$XDG_DATA_HOME/aurorae/themes" \
        "$XDG_DATA_HOME/plasma/desktoptheme" \
        "$XDG_DATA_HOME/plasma/plasmoids" \
        "$XDG_DATA_HOME/plasma/wallpapers" \
        "$XDG_DATA_HOME/plasma/look-and-feel" \
        "$XDG_DATA_HOME/kwin/effects" \
        "$XDG_DATA_HOME/kwin/scripts" \
        "$XDG_DATA_HOME/color-schemes" \
        "$RICE_WALLPAPER_DIR"

    copyr "$ASSETS_DIR/icons" "$XDG_DATA_HOME/icons"
    copyr "$ASSETS_DIR/cursors" "$XDG_DATA_HOME/icons"
    copyr "$ASSETS_DIR/KDE Window Decorations" "$XDG_DATA_HOME/aurorae/themes"
    copyr "$ASSETS_DIR/plasma/desktoptheme" "$XDG_DATA_HOME/plasma/desktoptheme"
    copyr "$ASSETS_DIR/plasma/plasmoids" "$XDG_DATA_HOME/plasma/plasmoids"
    copyr "$ASSETS_DIR/plasma/wallpapers" "$XDG_DATA_HOME/plasma/wallpapers"

    if [[ -d "$ASSETS_DIR/plasma/look-and-feel" ]]; then
        copyr "$ASSETS_DIR/plasma/look-and-feel" "$XDG_DATA_HOME/plasma/look-and-feel"
    fi

    if [[ -d "$ASSETS_DIR/splash/mita" ]]; then
        copyr "$ASSETS_DIR/splash/mita" "$XDG_DATA_HOME/plasma/look-and-feel/mita"
    fi

    if [[ -d "$ASSETS_DIR/kwin/effects" ]]; then
        copyr "$ASSETS_DIR/kwin/effects" "$XDG_DATA_HOME/kwin/effects"
    fi

    if [[ -d "$ASSETS_DIR/kwin/scripts" ]]; then
        copyr "$ASSETS_DIR/kwin/scripts" "$XDG_DATA_HOME/kwin/scripts"
    fi

    if [[ -d "$ASSETS_DIR/color-schemes" ]]; then
        copyr "$ASSETS_DIR/color-schemes" "$XDG_DATA_HOME/color-schemes"
    fi

    cp -f "$SCRIPT_DIR/wallpapers/mita.mp4" "$RICE_VIDEO"
    cp -f "$ASSETS_DIR/sddm/mita.jpg" "$RICE_IMAGE"
}

apply_plasma_layout() {
    local src="$ASSETS_DIR/plasma-org.kde.plasma.desktop-appletsrc"
    local dst="$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
    local tmp_merged=""
    local src_id=""
    local dst_id=""
    local i=0
    local backup=""
    local dst_ids_re=""
    local sep=""
    local -a src_ids=()
    local -a dst_ids=()

    if [[ ! -f "$src" ]]; then
        warn "Widget layout file not found at $src; skipping desktop widget replication."
        return
    fi

    if [[ ! -f "$dst" ]]; then
        warn "Target Plasma layout file not found at $dst; skipping desktop widget replication."
        return
    fi

    mapfile -t src_ids < <(desktop_containment_ids "$src")
    mapfile -t dst_ids < <(desktop_containment_ids "$dst")

    if [[ ${#src_ids[@]} -eq 0 || ${#dst_ids[@]} -eq 0 ]]; then
        warn "Could not detect desktop containments for widget replication."
        return
    fi

    for dst_id in "${dst_ids[@]}"; do
        dst_ids_re+="$sep$dst_id"
        sep="|"
    done

    tmp_merged="$(mktemp)" || {
        warn "Could not allocate temp file for desktop widget replication."
        return
    }

    awk -v ids_re="$dst_ids_re" '
        /^\[/ {
            skip = 0
            if (match($0, /^\[Containments\]\[([0-9]+)\]/, m)) {
                cid = m[1]
                if (cid ~ ("^(" ids_re ")$")) {
                    skip = 1
                }
            }
        }
        !skip { print }
    ' "$dst" > "$tmp_merged"

    for i in "${!dst_ids[@]}"; do
        dst_id="${dst_ids[$i]}"
        src_id="${src_ids[$((i % ${#src_ids[@]}))]}"
        awk -v src_cid="$src_id" -v dst_cid="$dst_id" '
            /^\[/ {
                in_block = ($0 ~ ("^\\[Containments\\]\\[" src_cid "\\]"))
                if (in_block) {
                    gsub("\\[Containments\\]\\[" src_cid "\\]", "[Containments][" dst_cid "]")
                    print
                }
                next
            }
            in_block { print }
        ' "$src" >> "$tmp_merged"
    done

    backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    cp -f "$dst" "$backup" || true
    if cp -f "$tmp_merged" "$dst"; then
        info "Desktop widgets replicated with source positions (panels untouched)."
    else
        warn "Failed to write merged desktop widget layout."
    fi

    rm -f "$tmp_merged"
}

apply_theme_config() {
    write_cfg "kdeglobals" "ColorScheme" "BreezeBlack" "General"
    write_cfg "kdeglobals" "Theme" "Vortex-Dark-Icons" "Icons"
    write_cfg "kdeglobals" "widgetStyle" "Breeze" "KDE"

    write_cfg "plasmarc" "name" "Ghost" "Theme"
    write_cfg "kcminputrc" "cursorTheme" "Mita Cursor" "Mouse"
    write_cfg "kcminputrc" "cursorSize" "24" "Mouse"
    write_cfg "ksplashrc" "Theme" "mita" "KSplash"
    write_cfg "ksplashrc" "Engine" "KSplashQML" "KSplash"

    write_cfg "kwinrc" "library" "org.kde.kwin.aurorae" "org.kde.kdecoration2"
    write_cfg "kwinrc" "theme" "__aurorae__svg__Xenon" "org.kde.kdecoration2"

    write_cfg_bool "kwinrc" "kwin6_effect_glitchEnabled" "true" "Plugins"
    write_cfg "kwinrc" "Scale" "2.1" "Effect-kwin6_effect_glitch"
    write_cfg "kwinrc" "Strength" "3.1" "Effect-kwin6_effect_glitch"

    write_cfg_bool "kwinrc" "klearEnabled" "true" "Plugins"
    write_cfg "kwinrc" "userSetOpacity" "83" "Script-klear"

    mkdir -p "$HOME/.icons/default"
    cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=Mita Cursor
EOF
}

apply_cursor_theme_live() {
    if have plasma-apply-cursortheme; then
        plasma-apply-cursortheme "Mita Cursor" >/dev/null 2>&1 || true
    fi
}

desktop_containment_ids() {
    local appletsrc="${1:-$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc}"
    [[ -f "$appletsrc" ]] || return 0

    awk '
        /^\[Containments\]\[[0-9]+\]$/ {
            id=$0
            sub(/^\[Containments\]\[/, "", id)
            sub(/\]$/, "", id)
        }
        /^plugin=org\.kde\.desktopcontainment$/ && id != "" {
            print id
            id=""
        }
    ' "$appletsrc" | sort -n -u
}

set_sddm_current_in_conf() {
    local conf_path="$1"
    local tmp_in=""
    local tmp_out=""

    tmp_in="$(mktemp)" || return 1
    tmp_out="$(mktemp)" || {
        rm -f "$tmp_in"
        return 1
    }

    if runsudo test -f "$conf_path"; then
        if ! runsudo cat "$conf_path" > "$tmp_in"; then
            rm -f "$tmp_in" "$tmp_out"
            return 1
        fi
    else
        : > "$tmp_in"
    fi

    awk -v theme="$SDDM_THEME_ID" '
        BEGIN { in_theme=0; wrote_current=0; saw_theme=0 }
        /^\[Theme\]/ {
            saw_theme=1
            in_theme=1
            print
            next
        }
        /^\[/ {
            if (in_theme && !wrote_current) {
                print "Current=" theme
                wrote_current=1
            }
            in_theme=0
            print
            next
        }
        {
            if (in_theme && $0 ~ /^Current=/) {
                if (!wrote_current) {
                    print "Current=" theme
                    wrote_current=1
                }
                next
            }
            print
        }
        END {
            if (!wrote_current) {
                if (!saw_theme) {
                    print ""
                    print "[Theme]"
                }
                print "Current=" theme
            }
        }
    ' "$tmp_in" > "$tmp_out"

    runsudo install -m 0644 "$tmp_out" "$conf_path"
    rm -f "$tmp_in" "$tmp_out"
}

apply_video_wallpaper_config() {
    local appletsrc="$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
    local video_urls_json
    printf -v video_urls_json '[{"filename":"%s","enabled":true,"duration":0,"customDuration":0,"playbackRate":0,"loop":false}]' "$RICE_VIDEO_URI"

    if [[ -f "$appletsrc" ]]; then
        local id
        while IFS= read -r id; do
            [[ -n "$id" ]] || continue
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "wallpaperplugin" "$VIDEO_WALLPAPER_PLUGIN" "Containments" "$id"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "LastVideo" "$RICE_VIDEO_URI" "Containments" "$id" "Wallpaper" "$VIDEO_WALLPAPER_PLUGIN" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "LastVideoPosition" "0" "Containments" "$id" "Wallpaper" "$VIDEO_WALLPAPER_PLUGIN" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "VideoUrls" "$video_urls_json" "Containments" "$id" "Wallpaper" "$VIDEO_WALLPAPER_PLUGIN" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "Image" "$RICE_IMAGE_URI" "Containments" "$id" "Wallpaper" "org.kde.image" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "SlidePaths" "$RICE_WALLPAPER_DIR" "Containments" "$id" "Wallpaper" "org.kde.image" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "Image" "$RICE_IMAGE_URI" "Containments" "$id" "Wallpaper" "org.kde.slideshow" "General"
            write_cfg "plasma-org.kde.plasma.desktop-appletsrc" "SlidePaths" "$RICE_WALLPAPER_DIR" "Containments" "$id" "Wallpaper" "org.kde.slideshow" "General"
        done < <(desktop_containment_ids)
    fi

    local qdbus_cmd=""
    if have qdbus6; then
        qdbus_cmd="qdbus6"
    elif have qdbus; then
        qdbus_cmd="qdbus"
    fi

    if [[ -n "$qdbus_cmd" ]] && pgrep -x plasmashell >/dev/null 2>&1; then
        local js
        js="$(cat <<EOF
var plugin = "$VIDEO_WALLPAPER_PLUGIN";
var videoUri = "$RICE_VIDEO_URI";
var imageUri = "$RICE_IMAGE_URI";
var slidePath = "$RICE_WALLPAPER_DIR";
var urls = '[{"filename":"' + videoUri + '","enabled":true,"duration":0,"customDuration":0,"playbackRate":0,"loop":false}]';
desktops().forEach(function(d) {
  d.wallpaperPlugin = plugin;
  d.currentConfigGroup = ["Wallpaper", plugin, "General"];
  d.writeConfig("LastVideo", videoUri);
  d.writeConfig("LastVideoPosition", "0");
  d.writeConfig("VideoUrls", urls);
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", imageUri);
  d.writeConfig("SlidePaths", slidePath);
  d.currentConfigGroup = ["Wallpaper", "org.kde.slideshow", "General"];
  d.writeConfig("Image", imageUri);
  d.writeConfig("SlidePaths", slidePath);
});
EOF
)"
        "$qdbus_cmd" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$js" >/dev/null 2>&1 || true
    fi
}

install_sddm_theme() {
    local src="$ASSETS_DIR/sddm"
    local dst="/usr/share/sddm/themes/$SDDM_THEME_ID"

    [[ -d "$src" ]] || return 0

    if [[ -d "$dst" ]]; then
        runsudo mv "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)" || return 1
    fi

    runsudo mkdir -p "$dst" || return 1
    runsudo cp -a "$src"/. "$dst"/ || return 1
    runsudo mkdir -p /etc/sddm.conf.d || return 1
    printf '[Theme]\nCurrent=%s\n' "$SDDM_THEME_ID" | runsudo tee /etc/sddm.conf.d/zzzz-myrice-theme.conf >/dev/null || return 1
    if ! set_sddm_current_in_conf "/etc/sddm.conf"; then
        warn "Could not update /etc/sddm.conf with the selected SDDM theme."
    fi
    if have systemctl; then
        runsudo systemctl enable sddm.service >/dev/null 2>&1 || true
        if runsudo systemctl is-active sddm.service >/dev/null 2>&1; then
            runsudo systemctl reload sddm.service >/dev/null 2>&1 || true
        fi
    fi
    if ! runsudo test -f "/usr/share/sddm/themes/$SDDM_THEME_ID/metadata.desktop"; then
        warn "SDDM theme files were copied but metadata.desktop is missing in destination."
    fi

    info "SDDM theme configured: $SDDM_THEME_ID"
}

reload_session() {
    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        warn "Plasma shell is not running. config will apply on next login"
        return
    fi

    if have qdbus6; then
        qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.reloadConfig >/dev/null 2>&1 || true
    elif have qdbus; then
        qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.reloadConfig >/dev/null 2>&1 || true
    fi

    if have kquitapp6; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
        nohup plasmashell >/dev/null 2>&1 &
    elif have kquitapp5; then
        kquitapp5 plasmashell >/dev/null 2>&1 || true
        nohup plasmashell >/dev/null 2>&1 &
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local answer=""
    while true; do
        read -r -p "$prompt " answer || return 1
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

install_cool_retro_term_from_package() {
    if have pacman && pacman -Si cool-retro-term >/dev/null 2>&1; then
        info "Installing cool-retro-term from pacman package..."
        if ! runsudo pacman -S --needed --noconfirm cool-retro-term; then
            warn "pacman install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    if have apt-get && have apt-cache && apt-cache show cool-retro-term >/dev/null 2>&1; then
        info "Installing cool-retro-term from apt package..."
        if ! runsudo apt-get update; then
            warn "apt-get update failed before cool-retro-term install."
            return 1
        fi
        if ! runsudo apt-get install -y cool-retro-term; then
            warn "apt install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    if have dnf && dnf info cool-retro-term >/dev/null 2>&1; then
        info "Installing cool-retro-term from dnf package..."
        if ! runsudo dnf install -y cool-retro-term; then
            warn "dnf install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    if have zypper && zypper search --match-exact cool-retro-term 2>/dev/null | grep -Fq "cool-retro-term"; then
        info "Installing cool-retro-term from zypper package..."
        if ! runsudo zypper --non-interactive install --auto-agree-with-licenses cool-retro-term; then
            warn "zypper install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    if have paru && paru -Si cool-retro-term >/dev/null 2>&1; then
        info "Installing cool-retro-term from paru package..."
        if ! paru -S --needed --noconfirm cool-retro-term; then
            warn "paru install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    if have yay && yay -Si cool-retro-term >/dev/null 2>&1; then
        info "Installing cool-retro-term from yay package..."
        if ! yay -S --needed --noconfirm cool-retro-term; then
            warn "yay install failed for cool-retro-term."
            return 1
        fi
        return 0
    fi

    return 1
}

detect_qmake() {
    local cmd
    for cmd in qmake6 qmake-qt5 qmake; do
        if have "$cmd"; then
            printf '%s\n' "$cmd"
            return 0
        fi
    done
    return 1
}

install_cool_retro_term_from_git() {
    local repo_url="https://github.com/Swordfish90/cool-retro-term.git"
    local tmp_dir=""
    local qmake_cmd=""

    if ! have git; then
        warn "git is required for cool-retro-term source install."
        return 1
    fi

    if ! have make; then
        warn "make is required for cool-retro-term source install."
        return 1
    fi

    qmake_cmd="$(detect_qmake || true)"
    if [[ -z "$qmake_cmd" ]]; then
        warn "qmake (qmake6/qmake-qt5/qmake) is required for cool-retro-term source install."
        return 1
    fi

    tmp_dir="$(mktemp -d)" || {
        warn "Could not create temporary directory for cool-retro-term source install."
        return 1
    }
    info "Installing cool-retro-term from git source..."
    if ! git clone --depth 1 "$repo_url" "$tmp_dir/cool-retro-term"; then
        warn "git clone failed for cool-retro-term."
        rm -rf "$tmp_dir"
        return 1
    fi
    if ! pushd "$tmp_dir/cool-retro-term" >/dev/null; then
        warn "Could not enter cool-retro-term source directory."
        rm -rf "$tmp_dir"
        return 1
    fi
    if ! "$qmake_cmd"; then
        warn "qmake failed for cool-retro-term."
        popd >/dev/null || true
        rm -rf "$tmp_dir"
        return 1
    fi
    if ! make -j"$(nproc 2>/dev/null || echo 2)"; then
        warn "make failed for cool-retro-term."
        popd >/dev/null || true
        rm -rf "$tmp_dir"
        return 1
    fi
    if ! runsudo make install; then
        warn "make install failed for cool-retro-term."
        popd >/dev/null || true
        rm -rf "$tmp_dir"
        return 1
    fi
    popd >/dev/null || true
    rm -rf "$tmp_dir"
    return 0
}

create_cool_retro_term_shortcut() {
    local desktop_dir="$HOME/Desktop"
    local theme_dir="${XDG_DATA_HOME:-$HOME/.local/share}/cool-retro-term/themes"
    local theme_file="$theme_dir/CRT_theme.json"
    local launcher_dir="$HOME/.local/bin"
    local launcher_file="$launcher_dir/start-crt.sh"
    local desktop_file=""
    local xdg_desktop=""

    if have xdg-user-dir; then
        xdg_desktop="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
        if [[ -n "$xdg_desktop" ]]; then
            desktop_dir="$xdg_desktop"
        fi
    fi

    desktop_file="$desktop_dir/TERMINAL.desktop"

    if ! mkdir -p "$theme_dir" "$launcher_dir" "$desktop_dir"; then
        warn "Could not create shortcut/theme directories."
        return 1
    fi
    if ! cp -f "$SCRIPT_DIR/CRT_theme.json" "$theme_file"; then
        warn "Could not copy CRT_theme.json for cool-retro-term launcher."
        return 1
    fi

    if ! cat > "$launcher_file" <<'EOF'
set -euo pipefail

THEME_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/cool-retro-term/themes/CRT_theme.json"
DB_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/cool-retro-term/cool-retro-term/QML/OfflineStorage/Databases"
PROFILE_NAME="arcxlo theme"

if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$THEME_FILE" ]] && [[ -d "$DB_ROOT" ]]; then
    if command -v jq >/dev/null 2>&1; then
        theme_json="$(jq -c . "$THEME_FILE" 2>/dev/null || tr -d '\r\n' < "$THEME_FILE")"
    else
        theme_json="$(tr -d '\r\n' < "$THEME_FILE")"
    fi

    if [[ -z "$theme_json" ]]; then
        exec cool-retro-term "$@"
    fi

    theme_json_sql=${theme_json//\'/\'\'}
    theme_json_for_obj=${theme_json//\\/\\\\}
    theme_json_for_obj=${theme_json_for_obj//\"/\\\"}
    fallback_profiles='[{"text":"'"$PROFILE_NAME"'","obj_string":"'"$theme_json_for_obj"'"}]'

    while IFS= read -r db_path; do
        current_profiles="$(sqlite3 "$db_path" "SELECT value FROM settings WHERE setting='_CUSTOM_PROFILES';" 2>/dev/null || true)"
        if command -v jq >/dev/null 2>&1; then
            if [[ -z "$current_profiles" ]]; then
                current_profiles="[]"
            fi
            custom_profiles="$(jq -c \
                --arg name "$PROFILE_NAME" \
                --argjson theme "$theme_json" \
                '((if type == "array" then . else [] end) | map(select(.text != $name))) + [{"text": $name, "obj_string": ($theme | tojson)}]' \
                <<<"$current_profiles" 2>/dev/null || printf '%s' "$fallback_profiles")"
        else
            custom_profiles="$fallback_profiles"
        fi

        custom_profiles_sql=${custom_profiles//\'/\'\'}
        sqlite3 "$db_path" \
            "INSERT INTO settings(setting, value) VALUES('_CUSTOM_PROFILES', '$custom_profiles_sql') ON CONFLICT(setting) DO UPDATE SET value=excluded.value;" \
            >/dev/null 2>&1 || true

        sqlite3 "$db_path" \
            "INSERT INTO settings(setting, value) VALUES('_CURRENT_PROFILE', '$theme_json_sql') ON CONFLICT(setting) DO UPDATE SET value=excluded.value;" \
            >/dev/null 2>&1 || true
    done < <(find "$DB_ROOT" -maxdepth 1 -type f -name '*.sqlite' 2>/dev/null)
fi

exec cool-retro-term --profile "$PROFILE_NAME" "$@"
EOF
    then
        warn "Could not create cool-retro-term launcher script."
        return 1
    fi
    if ! chmod +x "$launcher_file"; then
        warn "Could not make cool-retro-term launcher executable."
        return 1
    fi

    if ! cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=TERMINAL
Comment=Launch cool-retro-term with arcxlo CRT profile
Exec=bash $launcher_file
Icon=cool-retro-term
Terminal=false
Categories=System
StartupNotify=true
EOF
    then
        warn "Could not create desktop shortcut for cool-retro-term."
        return 1
    fi
    if ! chmod +x "$desktop_file"; then
        warn "Could not make desktop shortcut executable."
        return 1
    fi

    if have gio; then
        gio set "$desktop_file" metadata::trusted true >/dev/null 2>&1 || true
    fi
	chmod +x $launcher_file
	chmod *x $desktop_file
    info "Desktop shortcut created: $desktop_file"
}

install_cool_retro_term_optional() {
    if have cool-retro-term; then
        info "cool-retro-term is already installed."
    else
        if install_cool_retro_term_from_package; then
            info "cool-retro-term installed from package manager."
        else
            warn "No cool-retro-term package was found. Falling back to git source install."
            if ! install_cool_retro_term_from_git; then
                warn "Git source installation failed for cool-retro-term."
                return 1
            fi
            info "cool-retro-term installed from git source."
        fi
    fi

    if have cool-retro-term; then
        if ! create_cool_retro_term_shortcut; then
            warn "Could not create cool-retro-term desktop shortcut."
            return 1
        fi
    else
        warn "cool-retro-term is not available after installation attempts."
        return 1
    fi
}


detect_pip() {
    if command -v pip3 &>/dev/null; then
        echo "pip3"
        return 0
    fi

    if command -v pip &>/dev/null; then
        echo "pip"
        return 0
    fi
    if command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG="python3-pip"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG="python-pip"
    elif command -v apt-get &>/dev/null; then
        PKG_MGR="apt-get"
        PKG="python3-pip"
    else
        echo "Error: No known package manager (dnf/pacman/apt) found."
        exit 1
    fi

    echo "Installing pip via $PKG_MGR…" >&2

    case $PKG_MGR in
        dnf)
            sudo dnf install -y $PKG
            ;;
        pacman)
            sudo pacman -Sy --noconfirm $PKG
            ;;
        apt-get)
            sudo apt-get update -qq
            sudo apt-get install -y $PKG
            ;;
    esac

    if command -v pip3 &>/dev/null; then
        echo "pip3"
    elif command -v pip &>/dev/null; then
        echo "pip"
    else
        echo "Error: pip installation failed."
        exit 1
    fi
}

install_nekocli_optional() {
    info "Installing NekoCLI..."
	PIP_BIN=$(detect_pip)
	"$PIP_BIN" install nekocli --break-system-packages

	info "NekoCLI installation complete."
}

print_done_ascii() {
    cat <<'EOF'
 ____                        _
|  _ \  ___  _ __   ___    | |
| | | |/ _ \| '_ \ / _ \   | |
| |_| | (_) | | | |  __/   |_|
|____/ \___/|_| |_|\___|   (_)

--------------------------------------
EOF
}

print_logout_notice() {
    cat <<'EOF'

+===============================================================+
|            LOG OUT AND LOG BACK IN TO APPLY EVERYTHING       |
|                  FULLY (SPLASH, SDDM, WIDGETS)               |
+===============================================================+

EOF
}

logout_now() {
    local os_name=""
    os_name="$(uname -s 2>/dev/null || true)"

    if [[ "$os_name" == "Darwin" ]] && have osascript; then
        osascript -e 'tell application "System Events" to log out' >/dev/null 2>&1 && return 0
    fi

    if have qdbus6; then
        qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout >/dev/null 2>&1 && return 0
        qdbus6 org.kde.ksmserver /KSMServer logout 0 0 0 >/dev/null 2>&1 && return 0
    fi

    if have qdbus; then
        qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout >/dev/null 2>&1 && return 0
        qdbus org.kde.ksmserver /KSMServer logout 0 0 0 >/dev/null 2>&1 && return 0
    fi

    if have gnome-session-quit; then
        gnome-session-quit --logout --no-prompt >/dev/null 2>&1 && return 0
    fi

    if have cinnamon-session-quit; then
        cinnamon-session-quit --logout --no-prompt >/dev/null 2>&1 && return 0
    fi

    if have xfce4-session-logout; then
        xfce4-session-logout --logout >/dev/null 2>&1 && return 0
    fi

    if have loginctl && [[ -n "${XDG_SESSION_ID:-}" ]]; then
        loginctl terminate-session "$XDG_SESSION_ID" >/dev/null 2>&1 && return 0
    fi

    return 1
}

main() {
    print_title_banner
    print_section_banner "Starting Install"
    info "Installing and applying KDE theme assets..."
    install_assets
    apply_plasma_layout
    apply_theme_config
    apply_cursor_theme_live
    apply_video_wallpaper_config
    if ! install_sddm_theme; then
        warn "Could not install/apply SDDM theme automatically (sudo required)."
    fi
    reload_session

    print_section_banner "Applied"
    info "  Colors: BreezeBlack"
    info "  Application Style: Breeze"
    info "  Plasma Style: Ghost"
    info "  Window Decorations: Xenon"
    info "  Icons: Vortex-Dark-Icons"
    info "  Cursors: Mita Cursor"
    info "  Splash: mita"
    info "  SDDM: $SDDM_THEME_ID"
    info "  Animation: Glitch (Burn-My-Windows) + semi-transparent windows"
    info "  Wallpaper: $RICE_VIDEO"

    if [[ ! -t 0 ]]; then
        print_section_banner "Optional Installs"
        warn "No interactive terminal detected; skipping optional installs."
        print_done_ascii
        print_logout_notice
        return
    fi

    print_section_banner "Optional Installs"
    if prompt_yes_no "do you wanna install cool-retro-term? y/n"; then
        if ! install_cool_retro_term_optional; then
            warn "cool-retro-term installation failed."
        fi
    fi

    if prompt_yes_no "do you want to install Terminal AI - NekoCLI? y/n"; then
        if ! install_nekocli_optional; then
            warn "NekoCLI installation failed."
        fi
    fi

    print_done_ascii
    print_logout_notice
    if prompt_yes_no "Logout now? y/N"; then
        if ! logout_now; then
            warn "Could not trigger automatic logout on this desktop. Please logout manually."
        fi
    fi
}

main "$@"
