#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

LOG_FILE="/var/log/pdftk_installer.log"

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root or with sudo."
  echo "Attempting to switch to root..."

  # Call sudo without exec and exit after
  sudo "$0" "$@"

  # Exit here so that the original script does not continue
  exit 0
fi

# Continue with the rest of your script here
echo "Running as root."

# Function to detect the operating system and package manager
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    log "Detected OS: $OS"

    for pkg_manager in apt yum dnf zypper pacman apk; do
      if command -v $pkg_manager >/dev/null; then
        PKG_MANAGER=$pkg_manager
        log "Detected package manager: $PKG_MANAGER"
        return
      fi
    done

    log "Unsupported package manager"
    exit 1
  else
    log "Unsupported OS"
    exit 1
  fi
}

# Function to install Java JRE
install_java() {
  log "Installing Java JRE..."
  case $PKG_MANAGER in
  apt) apt update && apt install -y default-jre ;;
  yum | dnf) yum install -y java-11-openjdk || dnf install -y java-11-openjdk ;;
  zypper) zypper install -y java-11-openjdk ;;
  pacman) pacman -Syu --noconfirm jre11-openjdk ;;
  apk) apk add --no-cache openjdk11-jre ;;
  esac

  # Verify Java installation
  if ! java -version >/dev/null 2>&1; then
    log "Java installation failed."
    exit 1
  fi

  log "Java installed successfully."
}

# Function to install PDFtk using package manager or fall back to JAR installation
install_pdftk() {
  log "Attempting to install PDFtk..."

  # Helper function to attempt installation and fallback on failure
  install_pdftk_pkg() {
    log "Attempting to install PDFtk via $2..."
    if ! eval "$1"; then # Use eval to execute the command string properly
      log "PDFtk installation failed using $2. Falling back to JAR."
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
  esac

  log "PDFtk installed successfully."
}

# Function to download PDFtk from GitLab as a JAR file if not available in the repository
install_pdftk_jar() {
  log "Downloading PDFtk JAR file..."

  # Download PDFtk JAR file using wget or curl, depending on availability.
  if [ ! -f /usr/local/bin/pdftk.jar ]; then
    if command -v wget >/dev/null; then
      wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -O /usr/local/bin/pdftk.jar || {
        log "Failed to download PDFtk JAR file."
        exit 1
      }
    elif command -v curl >/dev/null; then
      curl -L https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -o /usr/local/bin/pdftk.jar || {
        log "Failed to download PDFtk JAR file."
        exit 1
      }
    else
      log "Neither wget nor curl is available."
      exit 1
    fi
  else
    log "PDFtk JAR file already exists, skipping download."
  fi

  # Create wrapper script for PDFtk.
  if [ ! -x /usr/local/bin/pdftk ]; then
    echo '#!/bin/sh' >/usr/local/bin/pdftk
    echo 'java -jar /usr/local/bin/pdftk.jar "$@"' >>/usr/local/bin/pdftk
    chmod +x /usr/local/bin/pdftk || {
      log "Failed to make PDFtk executable."
      exit 1
    }
  else
    log "PDFtk wrapper script already exists."
  fi

  log "PDFtk installed successfully from JAR."
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
    log "PDFtk installed successfully."
  else
    echo "PDFtk installation failed."
    exit 1
  fi
}

# Call the main function with all arguments passed to the script.
main "$@"
