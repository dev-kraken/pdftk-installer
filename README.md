# PDFtk Installer

This repository contains a shell script that automates the installation of PDFtk (PDF Toolkit) across various Linux distributions. The script first attempts to install PDFtk using the system's native package manager. If that fails, it falls back to installing the Java version of PDFtk directly from the project's GitLab repository.

## Features

- Detects the operating system and package manager automatically
- Installs Java Runtime Environment (JRE) if not present
- Attempts to install PDFtk using the system's package manager
- Falls back to downloading and setting up the Java version of PDFtk if the package manager installation fails
- Works on multiple Linux distributions including Debian/Ubuntu, Red Hat/CentOS, Fedora, openSUSE, Arch Linux, and Alpine Linux

## Usage

You can run this script directly using either wget or curl:

### Using wget:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/dev-kraken/pdftk-installer/main/install_pdftk.sh)
```
### Using curl:

```bash
bash <(curl -s https://raw.githubusercontent.com/dev-kraken/pdftk-installer/main/install_pdftk.sh)
```
### What the script does
1.  Detects the operating system and package manager
2.  Installs Java JRE if not already present
3.  Attempts to install PDFtk using the system's package manager
4.  If the package manager installation fails, it downloads the PDFtk JAR from GitLab and sets up a wrapper script
5.  Verifies the installation by running `pdftk --version`

### Requirements
*   Bash shell
*   sudo privileges
*   Internet connection

### Supported Distributions
*   Debian/Ubuntu (apt)
*   Red Hat/CentOS (yum)
*   Fedora (dnf)
*   openSUSE (zypper)
*   Arch Linux (pacman)
*   Alpine Linux (apk)

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check [issues page](https://github.com/dev-kraken/pdftk-installer/issues).

Give a ⭐️ if this project helped you!
