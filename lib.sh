#!/bin/bash

if [[ -z "$GRIM_DAWN_SAVE_DIR" ]]; then
    echo "$0: missing required environment variable GRIM_DAWN_SAVE_DIR" >&2
    exit 9
fi

_LIB_FILE_DIR=$(dirname "${BASH_SOURCE[0]}")

# .gst files are for Grim Dawn: Forgotten Gods"
STASH_SUFFIX='gst'

ACTIVE_STASH_FILE="${GRIM_DAWN_SAVE_DIR}/transfer.${STASH_SUFFIX}"
ACTIVE_STASH_FILE_BACKUP="${ACTIVE_STASH_FILE}.bak"
CURRENT_STASH_NAME_FILE="${GRIM_DAWN_SAVE_DIR}/.current-stash"

function validate_regular_file() {
    local f=$1
    if [[ -e "$f" && ! -f "$f" ]]; then
        echo "$0: '$f' exists but is not a regular file!" >&2
        exit 12
    fi
}

function current_stash_name() {
    local n=$(cat "$CURRENT_STASH_NAME_FILE" 2>/dev/null)

    if [[ -z "$n" && -e "$ACTIVE_STASH_FILE" ]]; then
        echo "$0: could not determine current stash name" >&2
        exit 13
    fi

    echo "$n"
}

function set_current_stash_name() {
    local n=$1

    if [[ -z "$n" ]]; then
        echo "$0: you must specify the stash name to set" >&2
        exit 14
    fi

    echo "$n" > "$CURRENT_STASH_NAME_FILE"
}

function stash_path() {
    local stash_name=$1

    if [[ -z "$stash_name" ]]; then
        echo "$0: you must specify the name of the stash to get the path for" >&2
        exit 15
    fi

    echo "${GRIM_DAWN_SAVE_DIR}/_stashes/${stash_name}.${STASH_SUFFIX}"
}

function template_path() {
    local template_name=$1

    if [[ -z "$template_name" ]]; then
        echo "$0: you must specify the name of the stash template to get the path for" >&2
        exit 15
    fi

    local template_filename="${template_name}.${STASH_SUFFIX}"
    local builtin_template_path="${_LIB_FILE_DIR}/stash_templates/${template_filename}"
    local save_template_path="${GRIM_DAWN_SAVE_DIR}/_stash_templates/${template_filename}"

    if [[ -f "$builtin_template_path" ]]; then
        echo "$builtin_template_path"
    else
        echo "$save_template_path"
    fi
}

function deactivate_current_stash() {
    validate_regular_file "$ACTIVE_STASH_FILE"

    if [[ -f "$ACTIVE_STASH_FILE" ]]; then
        local cs=$(current_stash_name)
        if [[ -z "$cs" ]]; then
            echo "$0: failed deactivating current stash; could not determine current stash name" >&2
            exit 16
        fi
        local sp=$(stash_path "$cs")

        if [[ -e "$sp" ]]; then
            echo "$0: failed deactivating current stash; stash file named '$cs' already exists!" >&2
            exit 16
        fi

        mkdir -p "$(dirname "$sp")"
        mv "$ACTIVE_STASH_FILE" "$(stash_path "$cs")"
    fi
    rm -f "$ACTIVE_STASH_FILE_BACKUP" "$CURRENT_STASH_NAME_FILE"
}

function activate_stash() {
    local stash_name=$1
    local sp=$(stash_path "$stash_name")

    if [[ "$stash_name" == "$(current_stash_name)" ]]; then
        echo "$0: stash named '$stash_name' is already active" >&2
        exit 0
    fi

    validate_regular_file "$sp"
    if [[ ! -f "$sp" ]]; then
        echo "$0: stash named '$stash_name' does not exist" >&2
        exit 17
    fi

    deactivate_current_stash
    mv "$sp" "$ACTIVE_STASH_FILE"
    set_current_stash_name "$stash_name"
}

function new_stash_from() {
    local source_template=$1
    local stash_name=$2

    tp=$(template_path "$source_template")
    sp=$(stash_path "$stash_name")

    if [[ "$(current_stash_name)" == "$stash_name" ]]; then
        echo "$0: failed creating new stash; active stash named '$stash_name' already exists!" >&2
        exit 18
    fi

    if [[ -e "$sp" ]]; then
        echo "$0: failed creating new stash; stash named '$stash_name' already exists!" >&2
        exit 18
    fi

    mkdir -p "$(dirname "$sp")"
    cp "$tp" "$sp"
}
