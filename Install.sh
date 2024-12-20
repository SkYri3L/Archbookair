#!/bin/bash

# Function to print messages
print_stage_message() {
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

print_message() {
    echo "$1"
}

# Function to check if a package is installed
is_installed() {
    local package=$1
    pacman -Qi "$package" &> /dev/null
}

# Function to install a pacman package if not already installed
install_package() {
  local package=$1
  if ! is_installed "$package"; then
    print_message "Installing $package..."
    sudo pacman -S "$package"
  else
    print_message "$package is already installed. Skipping."
  fi
}

# Function to install an AUR package using yay
install_aur_package() {
  local package=$1
  if ! yay -Q "$package" &> /dev/null; then
    print_message "Installing AUR package $package..."
    yay -S "$package"
  else
    print_message "AUR package $package is already installed. Skipping."
  fi
}


# Declare package lists
# Add your pacman packages here
declare -a pacman_packages=(
    "code"
    "btop"
    "spotify"
    "fastfetch"
    "fish"
    "obsidian"
    "rofi"
    "firefox"
    "steam"
    "wlogout"
    "swaylock"
    "ani-cli"
    "dolphin"
    "qt5ct"
    "qt6ct"
    "kvantum"
    "heroic-games-launcher"
    )
# Add your AUR packages here
declare -a aur_packages=(

    )


# Add Chaotic-AUR repository if not already added
add_chaotic_aur() {
  if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    print_stage_message "Adding chaotic-aur repository..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    return 0
  else
    print_stage_message "Chaotic-AUR repository is already configured. Skipping."
    return 1
  fi
}

# Install yay if not already installed
install_yay() {
  if ! command -v yay &> /dev/null; then
    print_stage_message "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    return 0
  else
    print_stage_message "yay is already installed. Skipping."
    return 1
  fi
}


# Main script logic
main() {

    install_yay
    sleep 0.5
    clear

    add_chaotic_aur
    sleep 0.5
    clear

    print_stage_message "Updating System..."
    sudo pacman -Syu --noconfirm
    print_stage_message "System Updated..."
    sleep 1
    clear

    # Install pacman packages
    print_stage_message "Installing pacman packages..."
    for package in "${pacman_packages[@]}"; do
    install_package "$package"
    done
    print_stage_message "Installed all pacmans packages"
    sleep 1
    clear

    # Install AUR packages
    print_stage_message "Installing AUR packages..."
    for package in "${aur_packages[@]}"; do
    install_aur_package "$package"
    done
    sleep 1
    clear

    # Set Fish as the default shell
    if [[ $SHELL != "/usr/bin/fish" ]]; then
    print_stage_message "Changing default shell to Fish..."
    chsh -s /usr/bin/fish
    else
    print_stage_message "Fish is already the default shell."
    fi
    sleep 1
    clear

    # All Tasks completed
    print_stage_message "All tasks completed successfully!"
}

# Run the main function
main

