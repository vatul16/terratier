#!/bin/bash
# Generates/refreshes terraform-docs Inputs/Outputs/Resources tables for every
# module under terraform-infra/modules, using the root .terraform-docs.yml config.
#
# Usage: ./terraform-infra/scripts/generate-tf-docs.sh
set -e

# Get script directory (works in Git Bash on Windows)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd 2>/dev/null || echo "$SCRIPT_DIR/..")"
MODULES_DIR="$REPO_ROOT/terraform-infra/modules"
CONFIG_FILE="$REPO_ROOT/.terraform-docs.yml"

# Check if terraform-docs is installed
if ! command -v terraform-docs &> /dev/null; then
    echo "❌ terraform-docs not found."
    echo ""
    echo "📦 Install it using one of these methods:"
    echo ""
    echo "  🍫 Chocolatey (Windows):"
    echo "     choco install terraform-docs"
    echo ""
    echo "  📥 Direct Download (Windows):"
    echo "     curl -L -o terraform-docs.zip https://github.com/terraform-docs/terraform-docs/releases/download/v0.16.0/terraform-docs-v0.16.0-windows-amd64.zip"
    echo "     unzip terraform-docs.zip"
    echo "     mv terraform-docs.exe /usr/local/bin/"
    echo ""
    echo "  🧹 Scoop (Windows):"
    echo "     scoop install terraform-docs"
    echo ""
    echo "  🐧 Linux (with Go):"
    echo "     go install github.com/terraform-docs/terraform-docs@latest"
    echo ""
    echo "  🍎 macOS:"
    echo "     brew install terraform-docs"
    echo ""
    exit 1
fi

echo "✅ terraform-docs found: $(terraform-docs --version 2>/dev/null | head -1 || echo 'installed')"

# Check if modules directory exists
if [ ! -d "$MODULES_DIR" ]; then
    echo "❌ Modules directory not found at: $MODULES_DIR"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "📁 Modules directory: $MODULES_DIR"
echo "📄 Config file: $CONFIG_FILE"
echo ""

# Scaffold README.md files only where missing
echo "📝 Scaffolding module README.md files (only where missing)..."
for module_path in "$MODULES_DIR"/*/; do
    # Skip if not a directory
    [ -d "$module_path" ] || continue
    
    module_name="$(basename "$module_path")"
    readme="$module_path/README.md"

    if [ ! -f "$readme" ]; then
        cat > "$readme" << EOF
# Module: \`$module_name\`

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
EOF
        echo "  ✅ created $readme"
    fi
done

echo ""
echo "🚀 Running terraform-docs recursively..."

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Using config: $CONFIG_FILE"
    terraform-docs --config "$CONFIG_FILE" "$MODULES_DIR"
else
    echo "⚠️  Config file not found at $CONFIG_FILE, using default settings"
    terraform-docs "$MODULES_DIR"
fi

echo ""
echo "✅ Done! Review and commit the updated module README.md files."