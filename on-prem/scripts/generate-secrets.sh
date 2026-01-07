#!/bin/bash
#
# Generate secrets for Currents on-prem configuration
#
# Usage:
#   ./generate-secrets.sh token [length]     - Generate a random token
#   ./generate-secrets.sh key <filename>     - Generate an RSA private key
#
# Examples:
#   ./generate-secrets.sh token              # 32-char token (default)
#   ./generate-secrets.sh token 64           # 64-char token
#   ./generate-secrets.sh key gitlab-key.pem # RSA 2048-bit key

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generate a random alphanumeric token
generate_token() {
    local length=${1:-32}
    head -c 512 /dev/urandom | LC_ALL=C tr -cd 'a-zA-Z0-9' | head -c "$length"
    echo ""
}

# Generate an RSA private key
generate_key() {
    local filename="$1"
    local bits=${2:-2048}
    
    if [ -z "$filename" ]; then
        echo "Error: Key filename is required"
        echo "Usage: $0 key <filename> [bits]"
        exit 1
    fi
    
    # Resolve path relative to on-prem directory if not absolute
    if [[ "$filename" != /* ]]; then
        filename="$SCRIPT_DIR/../$filename"
    fi
    
    if [ -f "$filename" ]; then
        read -p "File '$filename' already exists. Overwrite? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy] ]]; then
            echo "Aborted."
            exit 0
        fi
    fi
    
    openssl genrsa -out "$filename" "$bits" 2>/dev/null
    chmod 600 "$filename"
    echo "Generated $bits-bit RSA key: $filename"
}

# Show usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  token [length]      Generate a random alphanumeric token"
    echo "                      Default length: 32 characters"
    echo ""
    echo "  key <filename>      Generate an RSA private key (2048-bit)"
    echo "                      File path relative to on-prem directory"
    echo ""
    echo "Examples:"
    echo "  $0 token            # Generate a 32-char token"
    echo "  $0 token 64         # Generate a 64-char token"
    echo "  $0 key keys/app.pem # Generate RSA key at on-prem/keys/app.pem"
    echo ""
    echo "For .env file, you can use:"
    echo "  JWT_SECRET=\$($0 token 64)"
    echo "  API_KEY=\$($0 token)"
}

# Main
case "${1:-}" in
    token)
        generate_token "${2:-32}"
        ;;
    key)
        generate_key "$2" "${3:-2048}"
        ;;
    -h|--help|"")
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_usage
        exit 1
        ;;
esac

