#!/bin/bash

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    if command -v apt >/dev/null; then
      PKG_MANAGER="apt"
    elif command -v yum >/dev/null; then
      PKG_MANAGER="yum"
    elif command -v dnf >/dev/null; then
      PKG_MANAGER="dnf"
    elif command -v zypper >/dev/null; then
      PKG_MANAGER="zypper"
    elif command -v pacman >/dev/null; then
      PKG_MANAGER="pacman"
    elif command -v apk >/dev/null; then
      PKG_MANAGER="apk"
    else
      echo "Unsupported package manager"
      exit 1
    fi
  else
    echo "Unsupported OS"
    exit 1
  fi
}

install_java() {
  case $PKG_MANAGER in
    apt)
      sudo apt update && sudo apt install -y default-jre
      ;;
    yum|dnf)
      sudo $PKG_MANAGER install -y java-11-openjdk
      ;;
    zypper)
      sudo zypper install -y java-11-openjdk
      ;;
    pacman)
      sudo pacman -Syu --noconfirm jre11-openjdk
      ;;
    apk)
      apk add --no-cache openjdk11-jre
      ;;
  esac
}

install_pdftk() {
  case $PKG_MANAGER in
    apt)
      if sudo apt install -y pdftk; then
        return 0
      fi
      ;;
    yum|dnf)
      if sudo $PKG_MANAGER install -y pdftk; then
        return 0
      fi
      ;;
    zypper)
      if sudo zypper install -y pdftk; then
        return 0
      fi
      ;;
    pacman)
      if sudo pacman -S --noconfirm pdftk; then
        return 0
      fi
      ;;
    apk)
      if apk add --no-cache pdftk; then
        return 0
      fi
      ;;
  esac

  echo "PDFtk not available in system repositories. Falling back to JAR installation."
  install_pdftk_jar
}

install_pdftk_jar() {

  # Download PDFtk JAR file
  sudo wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -O /usr/local/bin/pdftk.jar

  # Create wrapper script
  echo '#!/bin/sh' | sudo tee /usr/local/bin/pdftk > /dev/null
  echo 'java -jar /usr/local/bin/pdftk.jar "$@"' | sudo tee -a /usr/local/bin/pdftk > /dev/null

  # Make the wrapper script executable
  sudo chmod +x /usr/local/bin/pdftk
}

main() {
  detect_os
  install_java
  install_pdftk
  echo "Java JRE and PDFtk installation complete."
  echo "Verifying PDFtk installation:"
  pdftk --version
}

main