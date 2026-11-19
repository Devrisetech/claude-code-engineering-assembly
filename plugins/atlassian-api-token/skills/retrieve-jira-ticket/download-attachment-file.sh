#!/bin/bash

# ============================================================================
# Downloads a JIRA attachment file to a specified local path
# ============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

OUT_FILE_PATH=""
ATTACHMENT_DOWNLOAD_URL=""
NETRC_FILE=""

cleanup() {
    if [[ -n "$NETRC_FILE" && -f "$NETRC_FILE" ]]; then
        rm -f "$NETRC_FILE"
    fi
}

trap cleanup EXIT

usage() {
    echo "Usage: $SCRIPT_NAME --out-file-path <path> --in-attachment-download-url <url>"
    echo "Options:"
    echo "  --out-file-path                Absolute path to save the downloaded file (required)"
    echo "  --in-attachment-download-url   Attachment file URL to download (required)"
    echo "  -h, --help                     Show this help"
    exit 0
}

validate_requirements() {
    if [[ -z "$OUT_FILE_PATH" ]]; then
        echo "Error: --out-file-path is required" >&2
        exit 1
    fi
    if [[ -z "$ATTACHMENT_DOWNLOAD_URL" ]]; then
        echo "Error: --in-attachment-download-url is required" >&2
        exit 1
    fi
    # The download URL comes from ticket content (attachment metadata, or an
    # inline reference resolved from the ticket body/comments), which is not
    # trusted input. Only ever send the Atlassian credential to a Jira Cloud
    # host over HTTPS - never follow it to an arbitrary host or over plain
    # HTTP, which would hand the credential to whoever controls that URL.
    if [[ ! "$ATTACHMENT_DOWNLOAD_URL" =~ ^https://[A-Za-z0-9.-]+\.atlassian\.net(/|$) ]]; then
        echo "Error: --in-attachment-download-url must be an https:// URL on an *.atlassian.net host, got: $ATTACHMENT_DOWNLOAD_URL" >&2
        exit 1
    fi
    if [[ -z "${MCP_ATLASSIAN_ACCOUNT_USERNAME:-}" ]]; then
        echo "Error: MCP_ATLASSIAN_ACCOUNT_USERNAME is not set" >&2
        exit 1
    fi
    if [[ -z "${MCP_ATLASSIAN_ACCOUNT_API_TOKEN:-}" ]]; then
        echo "Error: MCP_ATLASSIAN_ACCOUNT_API_TOKEN is not set" >&2
        exit 1
    fi
}

main() {
    validate_requirements

    # Credentials go in via a .netrc-style file, not `-u user:pass` on the
    # command line, so they never appear in `ps` output. curl's .netrc
    # matching is an exact hostname match, so this must be the download URL's
    # own host (e.g. "yourname.atlassian.net"), not the bare "atlassian.net".
    local host="${ATTACHMENT_DOWNLOAD_URL#https://}"
    host="${host%%/*}"
    NETRC_FILE="$(mktemp)"
    chmod 600 "$NETRC_FILE"
    printf 'machine %s login %s password %s\n' \
        "$host" "$MCP_ATLASSIAN_ACCOUNT_USERNAME" "$MCP_ATLASSIAN_ACCOUNT_API_TOKEN" > "$NETRC_FILE"

    if curl -fsSL \
        --netrc-file "$NETRC_FILE" \
        -o "$OUT_FILE_PATH" \
        "$ATTACHMENT_DOWNLOAD_URL"; then
        echo "The url is saved at the path: $OUT_FILE_PATH"
    else
        echo "Error: failed to download attachment from $ATTACHMENT_DOWNLOAD_URL" >&2
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --out-file-path)
            OUT_FILE_PATH="${2:?--out-file-path needs a value}"
            shift 2
            ;;
        --in-attachment-download-url)
            ATTACHMENT_DOWNLOAD_URL="${2:?--in-attachment-download-url needs a value}"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

main
