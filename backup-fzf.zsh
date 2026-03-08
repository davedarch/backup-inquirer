#!/bin/zsh

# backup-inquirer (fzf edition) - Semantic versioned backups with fuzzy finder UI
# Usage: ./backup-fzf.zsh [directory]
#   directory: optional path to backup from (defaults to current directory)
# Requires: fzf (brew install fzf)

BACKUP_ROOT="${1:-$(pwd)}"

# Excluded from listing and directory copies
EXCLUDE_LIST=("node_modules" ".git" "backup_public" "lib" ".DS_Store")

# ─── Preflight ───

if ! command -v fzf &>/dev/null; then
    echo "Error: fzf is required but not installed."
    echo "Install it with: brew install fzf"
    exit 1
fi

# ─── Helpers ───

is_excluded() {
    local name="$1"
    for exc in "${EXCLUDE_LIST[@]}"; do
        [[ "$name" == "$exc" ]] && return 0
    done
    return 1
}

# ─── Get available items ───
# Populates the global AVAILABLE_ITEMS array

get_available_items() {
    AVAILABLE_ITEMS=()
    for entry in "$BACKUP_ROOT"/*(N); do
        local name="${entry:t}"
        is_excluded "$name" && continue
        AVAILABLE_ITEMS+=("$name")
    done
}

# ─── Multi-select prompt via fzf ───
# Populates the global SELECTED_ITEMS array

prompt_for_items() {
    local -a items=("$@")
    SELECTED_ITEMS=()

    if (( ${#items} == 0 )); then
        echo "No available files or directories to backup."
        exit 1
    fi

    # Build labeled list for fzf
    local -a labeled=()
    for item in "${items[@]}"; do
        local type_label="[FILE]"
        [[ -d "$BACKUP_ROOT/$item" ]] && type_label="[DIR] "
        labeled+=("${type_label} ${item}")
    done

    # Run fzf multi-select
    local selection
    selection=$(printf '%s\n' "${labeled[@]}" | fzf --multi \
        --header="Select items to backup (Tab to toggle, Enter to confirm)" \
        --prompt="Backup> " \
        --marker="*" \
        --border=rounded \
        --info=inline \
        --reverse)

    if [[ -z "$selection" ]]; then
        echo "No items selected. Aborting."
        exit 1
    fi

    # Strip type labels to get plain names
    while IFS= read -r line; do
        local name="${line#\[FILE\] }"
        name="${name#\[DIR\]  }"
        SELECTED_ITEMS+=("$name")
    done <<< "$selection"
}

# ─── Version type prompt via fzf ───
# Sets VERSION_TYPE global (patch|minor|major)

prompt_for_version_type() {
    local item_name="$1"

    local choice
    choice=$(printf '%s\n' \
        "Patch (bug fixes) - x.x.X" \
        "Minor (new features) - x.X.0" \
        "Major (breaking changes) - X.0.0" \
        | fzf --header="Version increment for \"${item_name}\":" \
              --prompt="Version> " \
              --border=rounded \
              --reverse \
              --no-multi)

    case "$choice" in
        Patch*) VERSION_TYPE="patch" ;;
        Minor*) VERSION_TYPE="minor" ;;
        Major*) VERSION_TYPE="major" ;;
        *)
            echo "No version type selected. Defaulting to Patch."
            VERSION_TYPE="patch"
            ;;
    esac
}

# ─── Get next version number ───
# Returns version string via NEXT_VERSION global

get_next_version() {
    local item_name="$1"
    local base ext

    # Split name and extension (only for files)
    if [[ -f "$BACKUP_ROOT/$item_name" ]] && [[ "$item_name" == *.* ]]; then
        ext=".${item_name##*.}"
        base="${item_name%.*}"
    else
        ext=""
        base="$item_name"
    fi

    # Find existing versioned copies
    local latest_major=-1 latest_minor=0 latest_patch=0
    local escaped_ext="${ext//./\\.}"

    for entry in "$BACKUP_ROOT"/*(N); do
        local name="${entry:t}"
        if [[ -n "$ext" ]]; then
            if [[ "$name" =~ ^${base}_([0-9]+)\.([0-9]+)\.([0-9]+)${escaped_ext}$ ]]; then
                local maj=${match[1]} min=${match[2]} pat=${match[3]}
                if (( maj > latest_major || (maj == latest_major && min > latest_minor) || (maj == latest_major && min == latest_minor && pat > latest_patch) )); then
                    latest_major=$maj; latest_minor=$min; latest_patch=$pat
                fi
            fi
        else
            if [[ "$name" =~ ^${base}_([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
                local maj=${match[1]} min=${match[2]} pat=${match[3]}
                if (( maj > latest_major || (maj == latest_major && min > latest_minor) || (maj == latest_major && min == latest_minor && pat > latest_patch) )); then
                    latest_major=$maj; latest_minor=$min; latest_patch=$pat
                fi
            fi
        fi
    done

    # No existing versions found
    if (( latest_major < 0 )); then
        NEXT_VERSION="0.1.0"
        return
    fi

    # Prompt for version type
    prompt_for_version_type "$item_name"

    case "$VERSION_TYPE" in
        major)
            (( latest_major++ ))
            latest_minor=0
            latest_patch=0
            ;;
        minor)
            (( latest_minor++ ))
            latest_patch=0
            ;;
        patch)
            (( latest_patch++ ))
            ;;
    esac

    NEXT_VERSION="${latest_major}.${latest_minor}.${latest_patch}"
}

# ─── Copy directory with exclusions ───

copy_dir_filtered() {
    local src="$1" dst="$2"

    mkdir -p "$dst"

    for entry in "$src"/*(DN); do
        local name="${entry:t}"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        is_excluded "$name" && continue

        if [[ -d "$entry" ]]; then
            copy_dir_filtered "$entry" "$dst/$name"
        else
            cp -a "$entry" "$dst/$name"
        fi
    done
}

# ─── Main ───

main() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        echo "Error: Directory '$BACKUP_ROOT' does not exist."
        exit 1
    fi

    # Get available items
    get_available_items

    # Prompt for selection via fzf
    prompt_for_items "${AVAILABLE_ITEMS[@]}"

    echo ""
    echo "Starting backup process..."
    echo "Please wait..."

    for item in "${SELECTED_ITEMS[@]}"; do
        local src="$BACKUP_ROOT/$item"

        # Get next version number
        get_next_version "$item"

        if [[ -d "$src" ]]; then
            local new_name="${item}_${NEXT_VERSION}"
            copy_dir_filtered "$src" "$BACKUP_ROOT/$new_name"
            echo ""
            echo "Directory backed up: $new_name"
        elif [[ -f "$src" ]]; then
            local base="${item%.*}"
            local new_name
            if [[ "$item" == *.* ]]; then
                local ext="${item##*.}"
                new_name="${base}_${NEXT_VERSION}.${ext}"
            else
                new_name="${item}_${NEXT_VERSION}"
            fi
            cp -a "$src" "$BACKUP_ROOT/$new_name"
            echo ""
            echo "File backed up: $new_name"
        else
            echo ""
            echo "Skipping unsupported item type: $item"
        fi
    done

    echo ""
    echo "All selected items have been backed up successfully!"
    echo "Location: $BACKUP_ROOT"
}

main
