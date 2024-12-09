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
      apt update && apt install -y default-jre
      ;;
    yum|dnf)
      yum install -y java-11-openjdk || dnf install -y java-11-openjdk
      ;;
    zypper)
      zypper install -y java-11-openjdk
      ;;
    pacman)
      pacman -Syu --noconfirm jre11-openjdk
      ;;
    apk)
      apk add --no-cache openjdk11-jre
      ;;
  esac
}

install_pdftk() {
  case $PKG_MANAGER in
    apt)
      if apt install -y pdftk; then
        return 0
      fi
      ;;
    yum|dnf)
      if yum install -y pdftk || dnf install -y pdftk; then
        return 0
      fi
      ;;
    zypper)
      if zypper install -y pdftk; then
        return 0
      fi
      ;;
    pacman)
      if pacman -S --noconfirm pdftk; then
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
  # Download PDFtk JAR file using wget or curl, depending on availability.
  if command -v wget >/dev/null; then
    wget https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -O /usr/local/bin/pdftk.jar || {
        echo "Failed to download PDFtk JAR file."
        exit 1;
    }
  elif command -v curl >/dev/null; then
    curl -L https://gitlab.com/api/v4/projects/5024297/packages/generic/pdftk-java/v3.3.3/pdftk-all.jar -o /usr/local/bin/pdftk.jar || {
        echo "Failed to download PDFtk JAR file."
        exit 1;
    }
  else
    echo "Neither wget nor curl is available."
    exit 1;
  fi

  # Create wrapper script for PDFtk.
  echo '#!/bin/sh' > /usr/local/bin/pdftk
  echo 'java -jar /usr/local/bin/pdftk.jar "$@"' >> /usr/local/bin/pdftk

  # Make the wrapper script executable.
  chmod +x /usr/local/bin/pdftk || {
     echo "Failed to make PDFtk executable."
     exit 1;
   }
}

main() {
  detect_os || exit 1;
  install_java || exit 1;
  install_pdftk || exit 1;

  echo "Java JRE and PDFtk installation complete."

  # Verify PDFtk installation.
  echo "Verifying PDFtk installation:"

   if pdftk --version; then
       echo "PDFtk installed successfully."
   else
       echo "PDFtk installation failed."
       exit 1;
   fi
}

main "$@"