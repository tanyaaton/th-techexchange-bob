#!/bin/bash

################################################################################
# User-Level Java 21 and Maven 3.9.14 Installation Script
# For macOS/Linux users WITHOUT admin/sudo privileges
# Installs everything into: $HOME/.local
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Versions
JAVA_VERSION="21"
MAVEN_VERSION="3.9.15"
MAVEN_DIR_NAME="apache-maven-${MAVEN_VERSION}"

# User-local installation directories
LOCAL_DIR="${HOME}/.local"
JAVA_INSTALL_DIR="${LOCAL_DIR}/jdk-21"
MAVEN_INSTALL_DIR="${LOCAL_DIR}/${MAVEN_DIR_NAME}"

# Temporary download directory
TMP_DIR="${LOCAL_DIR}/tmp/java-maven-user-setup-$$"

# Shell config markers for idempotent updates
CONFIG_BEGIN="# >>> java-maven-user-setup >>>"
CONFIG_END="# <<< java-maven-user-setup <<<"

################################################################################
# Helper Functions
################################################################################

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BOLD}===============================================${NC}"
    echo -e "${BOLD} Java 21 & Maven 3.9.15 User Setup Script${NC}"
    echo -e "${BOLD}   No admin privileges / no sudo required${NC}"
    echo -e "${BOLD}===============================================${NC}"
    echo ""
    print_info "This script installs software only into your home directory."
    print_info "Java location : ${JAVA_INSTALL_DIR}"
    print_info "Maven location: ${MAVEN_INSTALL_DIR}"
    echo ""
}

cleanup() {
    if [ -d "${TMP_DIR}" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "${TMP_DIR}"
    fi
}

trap cleanup EXIT

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        print_error "Required command not found: $1"
        exit 1
    fi
}

################################################################################
# System Detection
################################################################################

detect_system() {
    print_info "Detecting operating system and architecture..."

    local os_type arch
    os_type="$(uname -s)"
    arch="$(uname -m)"

    case "${os_type}" in
        Darwin)
            OS="macos"
            case "${arch}" in
                arm64)
                    PLATFORM="macOS ARM64"
                    JAVA_DOWNLOAD_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-aarch64_bin.tar.gz"
                    ;;
                x86_64)
                    PLATFORM="macOS x64"
                    JAVA_DOWNLOAD_URL="https://download.oracle.com/java/21/latest/jdk-21_macos-x64_bin.tar.gz"
                    ;;
                *)
                    print_error "Unsupported macOS architecture: ${arch}"
                    exit 1
                    ;;
            esac
            ;;
        Linux)
            OS="linux"
            case "${arch}" in
                x86_64)
                    PLATFORM="Linux x64"
                    JAVA_DOWNLOAD_URL="https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz"
                    ;;
                aarch64|arm64)
                    PLATFORM="Linux ARM64"
                    JAVA_DOWNLOAD_URL="https://download.oracle.com/java/21/latest/jdk-21_linux-aarch64_bin.tar.gz"
                    ;;
                *)
                    print_error "Unsupported Linux architecture: ${arch}"
                    exit 1
                    ;;
            esac
            ;;
        *)
            print_error "Unsupported operating system: ${os_type}"
            exit 1
            ;;
    esac

    MAVEN_DOWNLOAD_URL="https://archive.apache.org/dist/maven/maven-3/3.9.15/binaries/apache-maven-3.9.15-bin.tar.gz"

    print_success "Detected platform: ${PLATFORM}"
}

detect_shell_config() {
    print_info "Detecting shell configuration file..."

    local current_shell shell_name
    current_shell="${SHELL:-}"

    if [ -n "${current_shell}" ]; then
        shell_name="$(basename "${current_shell}")"
    else
        shell_name=""
    fi

    case "${shell_name}" in
        zsh)
            SHELL_CONFIG="${HOME}/.zshrc"
            ;;
        bash)
            SHELL_CONFIG="${HOME}/.bashrc"
            ;;
        *)
            if [ -f "${HOME}/.zshrc" ]; then
                SHELL_CONFIG="${HOME}/.zshrc"
            else
                SHELL_CONFIG="${HOME}/.bashrc"
            fi
            ;;
    esac

    print_success "Using shell config: ${SHELL_CONFIG}"
}

################################################################################
# Preparation
################################################################################

prepare_directories() {
    print_info "Creating user-local directories if needed..."

    mkdir -p "${LOCAL_DIR}"
    mkdir -p "${LOCAL_DIR}/tmp"
    mkdir -p "${TMP_DIR}"

    print_success "Ensured ${LOCAL_DIR} exists"
}

################################################################################
# Installation Checks
################################################################################

check_java_installation() {
    if [ -x "${JAVA_INSTALL_DIR}/bin/java" ]; then
        local version_output
        version_output="$("${JAVA_INSTALL_DIR}/bin/java" -version 2>&1 | head -n 1 || true)"
        if echo "${version_output}" | grep -q "\"21"; then
            print_success "Java 21 already installed at ${JAVA_INSTALL_DIR}"
            return 0
        fi
        print_warning "Existing Java installation found at ${JAVA_INSTALL_DIR}, but version check did not match Java 21"
    else
        print_info "Java 21 not yet installed in ${JAVA_INSTALL_DIR}"
    fi
    return 1
}

check_maven_installation() {
    if [ -x "${MAVEN_INSTALL_DIR}/bin/mvn" ]; then
        local version_output
        version_output="$("${MAVEN_INSTALL_DIR}/bin/mvn" -version 2>&1 | head -n 1 || true)"
        if echo "${version_output}" | grep -q "Apache Maven ${MAVEN_VERSION}"; then
            print_success "Maven ${MAVEN_VERSION} already installed at ${MAVEN_INSTALL_DIR}"
            return 0
        fi
        print_warning "Existing Maven installation found at ${MAVEN_INSTALL_DIR}, but version check did not match ${MAVEN_VERSION}"
    else
        print_info "Maven ${MAVEN_VERSION} not yet installed in ${MAVEN_INSTALL_DIR}"
    fi
    return 1
}

################################################################################
# Download and Install
################################################################################

download_file() {
    local url="$1"
    local output_file="$2"

    print_info "Downloading: ${url}"
    if curl -fL --retry 3 --retry-delay 2 -o "${output_file}" "${url}"; then
        print_success "Downloaded to ${output_file}"
    else
        print_error "Download failed: ${url}"
        exit 1
    fi
}

install_java() {
    print_info "Installing Java 21 into ${JAVA_INSTALL_DIR}..."

    local archive_file extract_dir found_dir
    archive_file="${TMP_DIR}/jdk-21.tar.gz"
    extract_dir="${TMP_DIR}/java-extract"

    rm -rf "${extract_dir}"
    mkdir -p "${extract_dir}"

    download_file "${JAVA_DOWNLOAD_URL}" "${archive_file}"

    print_info "Extracting Java archive..."
    tar -xzf "${archive_file}" -C "${extract_dir}"

    if [ "${OS}" = "macos" ]; then
        found_dir="$(find "${extract_dir}" -maxdepth 2 -type d -name "jdk-21*.jdk" | head -n 1)"
        if [ -z "${found_dir}" ]; then
            print_error "Could not find extracted macOS JDK bundle"
            exit 1
        fi

        rm -rf "${JAVA_INSTALL_DIR}"
        mkdir -p "${JAVA_INSTALL_DIR}"
        cp -R "${found_dir}/Contents/Home/." "${JAVA_INSTALL_DIR}/"
    else
        found_dir="$(find "${extract_dir}" -maxdepth 2 -type d -name "jdk-21*" ! -path "*.jdk*" | head -n 1)"
        if [ -z "${found_dir}" ]; then
            print_error "Could not find extracted Linux JDK directory"
            exit 1
        fi

        rm -rf "${JAVA_INSTALL_DIR}"
        mkdir -p "${JAVA_INSTALL_DIR}"
        cp -R "${found_dir}/." "${JAVA_INSTALL_DIR}/"
    fi

    print_success "Java 21 installed at ${JAVA_INSTALL_DIR}"
}

install_maven() {
    print_info "Installing Maven ${MAVEN_VERSION} into ${MAVEN_INSTALL_DIR}..."

    local archive_file extract_dir found_dir
    archive_file="${TMP_DIR}/maven.tar.gz"
    extract_dir="${TMP_DIR}/maven-extract"

    rm -rf "${extract_dir}"
    mkdir -p "${extract_dir}"

    download_file "${MAVEN_DOWNLOAD_URL}" "${archive_file}"

    print_info "Extracting Maven archive..."
    tar -xzf "${archive_file}" -C "${extract_dir}"

    found_dir="${extract_dir}/${MAVEN_DIR_NAME}"
    if [ ! -d "${found_dir}" ]; then
        print_error "Could not find extracted Maven directory"
        exit 1
    fi

    rm -rf "${MAVEN_INSTALL_DIR}"
    mkdir -p "${MAVEN_INSTALL_DIR}"
    cp -R "${found_dir}/." "${MAVEN_INSTALL_DIR}/"

    print_success "Maven ${MAVEN_VERSION} installed at ${MAVEN_INSTALL_DIR}"
}

################################################################################
# Environment Configuration
################################################################################

ensure_shell_config_exists() {
    if [ ! -f "${SHELL_CONFIG}" ]; then
        print_info "Creating shell config file: ${SHELL_CONFIG}"
        touch "${SHELL_CONFIG}"
    fi
}

configure_environment() {
    print_info "Configuring environment variables in ${SHELL_CONFIG}..."

    ensure_shell_config_exists

    local backup_file temp_file
    backup_file="${SHELL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "${SHELL_CONFIG}" "${backup_file}"
    print_info "Backup created: ${backup_file}"

    temp_file="${TMP_DIR}/shell-config.cleaned"
    awk -v begin="${CONFIG_BEGIN}" -v end="${CONFIG_END}" '
        $0 == begin { skip=1; next }
        $0 == end { skip=0; next }
        skip != 1 { print }
    ' "${SHELL_CONFIG}" > "${temp_file}"

    cat >> "${temp_file}" <<EOF

${CONFIG_BEGIN}
# User-level Java and Maven configuration (no admin privileges required)
export JAVA_HOME="\$HOME/.local/jdk-21"
export MAVEN_HOME="\$HOME/.local/apache-maven-3.9.15"
export PATH="\$JAVA_HOME/bin:\$MAVEN_HOME/bin:\$PATH"
${CONFIG_END}
EOF

    mv "${temp_file}" "${SHELL_CONFIG}"

    export JAVA_HOME="${JAVA_INSTALL_DIR}"
    export MAVEN_HOME="${MAVEN_INSTALL_DIR}"
    export PATH="${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${PATH}"

    print_success "Environment variables updated in ${SHELL_CONFIG}"
}

################################################################################
# Verification
################################################################################

verify_installation() {
    print_info "Verifying Java and Maven installation..."

    echo ""
    print_info "Java version:"
    if "${JAVA_INSTALL_DIR}/bin/java" -version; then
        print_success "Java verification passed"
    else
        print_error "Java verification failed"
        exit 1
    fi

    echo ""
    print_info "Maven version:"
    if "${MAVEN_INSTALL_DIR}/bin/mvn" -version; then
        print_success "Maven verification passed"
    else
        print_error "Maven verification failed"
        exit 1
    fi

    echo ""
    print_info "Configured environment values for this session:"
    echo "JAVA_HOME=${JAVA_HOME}"
    echo "MAVEN_HOME=${MAVEN_HOME}"

    print_success "Installation verification completed successfully"
}

################################################################################
# Main Flow
################################################################################

main() {
    print_header

    if [ "${EUID}" -eq 0 ]; then
        print_warning "This script is intended for normal user accounts without admin privileges."
        print_warning "Running as root is unnecessary because everything installs under \$HOME/.local."
    fi

    require_command "curl"
    require_command "tar"
    require_command "find"
    require_command "awk"
    require_command "grep"

    detect_system
    detect_shell_config
    prepare_directories

    echo ""
    local java_ready=false
    local maven_ready=false

    if check_java_installation; then
        java_ready=true
    else
        install_java
        java_ready=true
    fi

    echo ""

    if check_maven_installation; then
        maven_ready=true
    else
        install_maven
        maven_ready=true
    fi

    echo ""

    if [ "${java_ready}" = true ] && [ "${maven_ready}" = true ]; then
        configure_environment
    fi

    echo ""
    verify_installation

    echo ""
    echo -e "${BOLD}===============================================${NC}"
    print_success "User-level installation completed"
    echo -e "${BOLD}===============================================${NC}"
    echo ""
    print_info "Installation locations:"
    echo "  Java : ${JAVA_INSTALL_DIR}"
    echo "  Maven: ${MAVEN_INSTALL_DIR}"
    echo ""
    print_info "To use the updated PATH in your current shell, run:"
    echo "  source ${SHELL_CONFIG}"
    echo ""
    print_info "This script is safe to run multiple times."
}

main

# Made with Bob
