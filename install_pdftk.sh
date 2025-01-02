#!/bin/bash

set -e

LOG_FILE="/var/log/pdftk_installer.log"

# Function to echo messages (instead of using `log` function)
echo_log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  echo "Attempting to switch to root..."

  # Get the script's full path
  if ! command -v realpath >/dev/null 2>&1; then
    echo "Command 'realpath' not found. Please install it and try again."
    exit 1
  fi

  SCRIPT_PATH="$(realpath "$0")"

  # Re-run the script with sudo, passing arguments as needed
  sudo bash "$SCRIPT_PATH" "$@"
  exit 0
fi

# Continue with the rest of your script here
echo_log "Running as root."
echo_log "Starting installation..."

# Function to detect the operating system and package manager
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    echo_log "Detected OS: $OS"

    for pkg_manager in apt yum dnf zypper pacman apk; do
      if command -v $pkg_manager >/dev/null 2>&1; then
        PKG_MANAGER=$pkg_manager
        echo_log "Detected package manager: $PKG_MANAGER"
        return
      fi
    done

    echo_log "Unsupported package manager"
    exit 1
  else
    echo_log "Unsupported OS"
    exit 1
  fi
}

# Function to install Java JRE
install_java() {
  echo_log "Installing Java JRE..."
  case $PKG_MANAGER in
  apt) apt update && apt install -y default-jre ;;
  yum | dnf) yum install -y java-11-openjdk || dnf install -y java-11-openjdk ;;
  zypper) zypper install -y java-11-openjdk ;;
  pacman) pacman -Syu --noconfirm jre11-openjdk ;;
  apk) apk add --no-cache openjdk11-jre ;;
  *)
    echo_log "Unsupported package manager: $PKG_MANAGER"
    exit 1
    ;;
  esac

  # Verify Java installation
  if ! java -version >/dev/null 2>&1; then
    echo_log "Java installation failed."
    exit 1
  fi

  echo_log "Java installed successfully."
}

# Function to install PDFtk using package manager or fall back to JAR installation
install_pdftk() {
  echo_log "Attempting to install PDFtk..."

  # Helper function to attempt installation and fallback on failure
  install_pdftk_pkg() {
    echo_log "Attempting to install PDFtk via $2..."
    if ! eval "$1"; then # Use eval to execute the command string properly
      echo_log "PDFtk installation failed using $2. Falling back to JAR."
      install_pdftk_jar
    fi
  }

  case $PKG_MANAGER in
  apt) install_pdftk_pkg "apt install -y pdftk" "apt" ;;
  yum) install_pdftk_pkg "yum install -y pdftk" "yum" ;;
  dnf) install_pdftk_pkg "dnf install -y pdftk" "dnf" ;;
  zypper) install_pdftk_pkg "zypper install -y pdftk" "zypper" ;;
  pacman) install_pdftk_pkg "pacman -S --noconfirm pdftk" "pacman" ;;
  apk) install_pdftk_pkg "apk add --no-cache pdftk" "apk" ;;
  *)
    echo_log "Unsupported package manager: $PKG_MANAGER"
    exit 1
    ;;
  esac

  echo_log "PDFtk installed successfully."
}

# Function to download PDFtk from GitLab as a JAR file if not available in the repository
install_pdftk_jar() {
  echo_log "Downloading PDFtk JAR file..."

  if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    echo_log "Neither wget nor curl is available. Please install one of them and try again."
    exit 1
  fi

  # Download PDFtk JAR file using wget or curl, depending on availability.
  if [ ! -f /usr/local/bin/pdftk.jar ]; then
    if command -v wget >/dev/null 2>&1; then
      wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -O /usr/local/bin/pdftk.jar || {
        echo_log "Failed to download PDFtk JAR file."
        exit 1
      }
    elif command -v curl >/dev/null 2>&1; then
      curl -L https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -o /usr/local/bin/pdftk.jar || {
        echo_log "Failed to download PDFtk JAR file."
        exit 1
      }
    fi
  else
    echo_log "PDFtk JAR file already exists, skipping download."
  fi

  # Create wrapper script for PDFtk.
  if [ ! -x /usr/local/bin/pdftk ]; then
    echo '#!/bin/sh' >/usr/local/bin/pdftk
    echo 'java -jar /usr/local/bin/pdftk.jar "$@"' >>/usr/local/bin/pdftk
    chmod +x /usr/local/bin/pdftk || {
      echo_log "Failed to make PDFtk executable."
      exit 1
    }
  else
    echo_log "PDFtk wrapper script already exists."
  fi

  echo_log "PDFtk installed successfully from JAR."
}

# Main function orchestrating the installation process
main() {
  detect_os || exit 1

  install_java || exit 1

  install_pdftk || exit 1

  echo "Java JRE and PDFtk installation complete."

  # Verify PDFtk installation.
  echo "Verifying PDFtk installation:"

  if pdftk --version >/dev/null 2>&1; then
    echo "PDFtk installed successfully."
    echo_log "PDFtk installed successfully."
  else
    echo "PDFtk installation failed."
    exit 1
  fi
}

# Call the main function with all arguments passed to the script.
main "$@"
