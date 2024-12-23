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
    sudo pacman -S "$package" --noconfirm
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

# Function to enable services
enable_services() {
  print_stage_message "Enabling required services..."
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable --now sddm.service
  print_message "Services enabled and started."
}

# Function to clean up temp files
cleanup() {
  print_stage_message "Cleaning up temporary files..."
  sudo pacman -Sc --noconfirm
  print_message "Temporary files cleaned up."
}


# Function to install Eucalyptus Drop theme for SDDM
install_theme() {
  local theme_name="Eucalyptus-Drop"
  local themes_dir="/usr/share/sddm/themes"
  local repo_url="https://gitlab.com/Matt.Jolly/sddm-eucalyptus-drop.git"
  local temp_dir="/tmp/eucalyptus_drop_theme"

  print_stage_message "Installing Eucalyptus Drop theme for SDDM..."

  # Create a temporary directory
  mkdir -p "$temp_dir"
  
  # Clone the Git repository
  print_message "Cloning Eucalyptus Drop theme repository..."
  if git clone "$repo_url" "$temp_dir"; then
    # Copy theme to SDDM themes directory
    if [[ -d "$temp_dir" ]]; then
      sudo mkdir -p "$themes_dir/$theme_name"
      sudo cp -r "$temp_dir"/* "$themes_dir/$theme_name/"
      print_message "Theme installed to $themes_dir/$theme_name."

      # Update SDDM configuration to use the new theme
      print_message "Setting Eucalyptus Drop as the default SDDM theme..."
      sudo sed -i "s/^Current=.*/Current=$theme_name/" /etc/sddm.conf || {
        echo "[Theme]" | sudo tee -a /etc/sddm.conf
        echo "Current=$theme_name" | sudo tee -a /etc/sddm.conf
      }
      print_message "Eucalyptus Drop theme set as the default."
    else
      print_message "Failed to copy Eucalyptus Drop theme. Directory not found."
    fi
  else
    print_message "Failed to clone Eucalyptus Drop theme repository."
  fi

  # Cleanup
  rm -rf "$temp_dir"
  print_message "Temporary files cleaned up."
}

# Function to copy Hyprland and wlogout configurations
copy_configs() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local source_dir="$script_dir" # Use the folder containing the script
  local hyprland_config_dir="$HOME/.config/hypr"
  local wlogout_config_dir="$HOME/.config/wlogout"

  print_stage_message "Copying Hyprland and wlogout configurations..."

  # Copy Hyprland configuration
  if [[ -d "$source_dir/hypr" ]]; then
    if [[ -d "$hyprland_config_dir" ]]; then
      local backup_dir="$hyprland_config_dir.bak_$(date +%Y%m%d%H%M%S)"
      cp -r "$hyprland_config_dir" "$backup_dir"
      print_message "Existing Hyprland config backed up to $backup_dir."
    fi
    mkdir -p "$hyprland_config_dir"
    cp -r "$source_dir/hypr/"* "$hyprland_config_dir/"
    print_message "Hyprland configuration copied to $hyprland_config_dir."
  else
    print_message "Hyprland configuration source directory not found. Skipping."
  fi

  # Copy wlogout configuration
  if [[ -d "$source_dir/wlogout" ]]; then
    if [[ -d "$wlogout_config_dir" ]]; then
      local backup_dir="$wlogout_config_dir.bak_$(date +%Y%m%d%H%M%S)"
      cp -r "$wlogout_config_dir" "$backup_dir"
      print_message "Existing wlogout config backed up to $backup_dir."
    fi
    mkdir -p "$wlogout_config_dir"
    cp -r "$source_dir/wlogout/"* "$wlogout_config_dir/"
    print_message "wlogout configuration copied to $wlogout_config_dir."
  else
    print_message "wlogout configuration source directory not found. Skipping."
  fi
}

# Add Chaotic-AUR repository if not already added
add_chaotic_aur() {
  if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    print_message "Adding chaotic-aur repository..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    return 0
  else
    print_message "Chaotic-AUR repository is already configured. Skipping."
    return 1
  fi
}

# Install yay if not already installed
install_yay() {
  if ! command -v yay &> /dev/null; then
    print_message "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    return 0
  else
    print_message "yay is already installed. Skipping."
    return 1
  fi
}


# Declare package lists
# Add your pacman packages here
declare -a pacman_packages=(
    "git" #SHOULD BE INSTALLED IF THIS SHELL SCRIPT IS RUNNING
    "base-devel"
    "networkmanager"
    "sddm"
    "kitty"
    "rofi"
    "fish"
    "firefox"
    "hyprland"
    "qt5ct"
    "qt6ct"
    "kvantum"
    "btop"
    "code"
    "wl-clipboard"
    "cliphist"
    "spotify"
    "fastfetch"
    "wlogout"
    "swaylock"
    "dolphin"
    "ranger"
    "vim"
    "unzip"
    "cava"
    "steam"
    "heroic-games-launcher"
    "obsidian"
    )

# Add your AUR packages here
declare -a aur_packages=(
    "7-zip-full"
    "hyprland-qtutils"
    "vesktop"
    "qimgv-git"
    )

# Main script logic
main() {

    # Log output to a file
    exec > >(tee -i setup.log)
    exec 2>&1

    # Installs YAY package manager
    print_stage_message "Installing YAY (Yet another Yogurt)"
    install_yay
    sleep 0.6
    
    # Add's Chaotic-aur to repo
    print_stage_message "Adding Chaotic-Aur Repo"
    add_chaotic_aur
    sleep 0.6
    
    # Update System + packages
    print_stage_message "Updating System..."
    if ! sudo pacman -Syu --noconfirm; then
      print_message "System update failed. Please check your network or pacman configuration."
      exit 1
    fi
    print_stage_message "System Updated..."
    sleep 0.6

    # Install pacman packages
    print_stage_message "Installing pacman packages..."
    for package in "${pacman_packages[@]}"; do
      install_package "$package"
    done
    print_stage_message "Installed all Pacman packages"
    sleep 0.6
    

    # Install AUR packages
    print_stage_message "Installing AUR packages..."
    for package in "${aur_packages[@]}"; do
      install_aur_package "$package"
    done
    print_stage_message "Installed all AUR packages"
    sleep 0.6
    

    # Set Fish as the default shell
    if [[ $SHELL != "/usr/bin/fish" ]]; then
    print_stage_message "Changing default shell to Fish..."
    chsh -s /usr/bin/fish
    else
    print_stage_message "Fish is already the default shell."
    fi
    sleep 0.6
    
    install_theme

    copy_configs

    #Enable Necessary services
    enable_services

    #Cleanup
    cleanup

    # All Tasks completed
    print_stage_message "All tasks completed successfully!"
    print_stage_message "Now you can install hyprpanel"
}

# Run the main function
main

