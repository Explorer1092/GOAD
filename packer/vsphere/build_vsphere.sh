#!/bin/bash

# Build script for vSphere Windows templates
# Usage: ./build_vsphere.sh [2019|2016|10|all|validate]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Template configurations (compatible with bash 3.x)
get_var_file() {
    case "$1" in
        2019) echo "windows_server2019_vsphere.pkvars.hcl" ;;
        2016) echo "windows_server2016_vsphere.pkvars.hcl" ;;
        10)   echo "windows_10_vsphere.pkvars.hcl" ;;
    esac
}

get_template_name() {
    case "$1" in
        2019) echo "Windows Server 2019" ;;
        2016) echo "Windows Server 2016" ;;
        10)   echo "Windows 10" ;;
    esac
}

check_config() {
    if [[ ! -f "config.auto.pkrvars.hcl" ]]; then
        echo -e "${RED}[ERROR]${NC} config.auto.pkrvars.hcl not found!"
        echo -e "${YELLOW}[INFO]${NC} Copy the template and configure it:"
        echo "  cp config.auto.pkrvars.hcl.template config.auto.pkrvars.hcl"
        echo "  # Edit config.auto.pkrvars.hcl with your vSphere settings"
        exit 1
    fi
}

init_packer() {
    echo -e "${GREEN}[+]${NC} Initializing Packer plugins..."
    packer init .
}

validate_template() {
    local var_file=$1
    echo -e "${GREEN}[+]${NC} Validating configuration with $var_file..."
    packer validate -var-file="$var_file" .
}

build_template() {
    local var_file=$1
    local name=$2
    echo -e "${GREEN}[+]${NC} Building $name template..."
    echo -e "${YELLOW}[INFO]${NC} This may take a while (30-60 minutes depending on your environment)"
    packer build -var-file="$var_file" -force .
    echo -e "${GREEN}[+]${NC} $name template build complete!"
}

process_template() {
    local key=$1
    local action=$2
    local var_file
    local name
    var_file=$(get_var_file "$key")
    name=$(get_template_name "$key")

    echo -e "\n${YELLOW}=== $name ===${NC}"
    validate_template "$var_file"
    if [[ "$action" == "build" ]]; then
        build_template "$var_file" "$name"
    fi
}

usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  2019      Build Windows Server 2019 template"
    echo "  2016      Build Windows Server 2016 template"
    echo "  10        Build Windows 10 template"
    echo "  all       Build all templates"
    echo "  validate  Validate all configurations (no build)"
    echo "  help      Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  1. Copy config.auto.pkrvars.hcl.template to config.auto.pkrvars.hcl"
    echo "  2. Edit config.auto.pkrvars.hcl with your vSphere settings"
    echo "  3. Upload Windows ISOs to your vSphere datastore"
    echo "  4. Update ISO paths in the .pkvars.hcl files"
    echo ""
    echo "Examples:"
    echo "  $0 2019           # Build Windows Server 2019 template"
    echo "  $0 validate       # Validate all configurations"
    echo "  $0 all            # Build all templates"
}

case "$1" in
    2019|2016|10)
        check_config
        init_packer
        process_template "$1" "build"
        ;;
    all)
        check_config
        init_packer
        echo -e "${GREEN}[+]${NC} Building all templates..."
        for key in 2019 2016 10; do
            process_template "$key" "build"
        done
        echo -e "\n${GREEN}[+]${NC} All templates built successfully!"
        ;;
    validate)
        check_config
        init_packer
        echo -e "${GREEN}[+]${NC} Validating all configurations..."
        for key in 2019 2016 10; do
            process_template "$key" "validate"
        done
        echo -e "\n${GREEN}[+]${NC} All configurations validated successfully!"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Invalid option: $1"
        echo ""
        usage
        exit 1
        ;;
esac
