#!/bin/bash

dir=$(pwd)

echo -ne "
-------------------------------------------------------------------------
                            Config DNF
-------------------------------------------------------------------------
"
echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf &&
echo "minrate=10k" | sudo tee -a /etc/dnf/dnf.conf &&
echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf &&
echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf

echo -ne "
-------------------------------------------------------------------------
                        Enable Copr repos
-------------------------------------------------------------------------
"

sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && 
sudo dnf copr enable -y solopasha/hyprland erikreider/SwayNotificationCenter errornointernet/packages tofik/nwg-shell

# Update package cache and install packages
sudo dnf update -y

echo -ne "
-------------------------------------------------------------------------
                        Install Basic Packages
-------------------------------------------------------------------------
"

sudo dnf -y upgrade --refresh

printf "Installing basic packages"

# packages neeeded
hypr_package=(
  bc
  curl
  findutils
  gawk
  git
  grim
  gvfs
  gvfs-mtp
  hyprpolkitagent
  ImageMagick
  inxi
  jq
  kitty
  kvantum
  nano
  network-manager-applet
  openssl
  pamixer
  pavucontrol
  pipewire-alsa
  pipewire-utils
  playerctl
  python3-requests
  python3-pip
  python3-pyquery
  qt5ct
  qt6ct
  qt6-qtsvg
  rofi-wayland
  slurp
  swappy
  unzip
  waybar
  wget2
  wl-clipboard
  wlogout
  xdg-user-dirs
  xdg-utils
  yad
)

hypr_package_2=(
  brightnessctl
  cava
  loupe
  gnome-system-monitor
  mousepad
  mpv
  mpv-mpris
  nvtop
  qalculate-gtk
)

personal_package=(
  @fonts
  util-linux-user
  go
  python3
  python
  python-pip
  fastfetch
  btop
  zsh
  openssl
  ranger
  ruby
  ruby-devel
  neovim
  rust
  ripgrep
  bat
  lm_sensors
  docker
)

copr_packages=(
  nwg-displays
  cliphist
  nwg-look
  SwayNotificationCenter
  pamixer
  swww
  wallust  
)

# List of packages to uninstall as it conflicts some packages
uninstall=(
  aylurs-gtk-shell
  dunst
  mako
  rofi
)

# Remove conflicting packages
for PKG in "${uninstall[@]}"; do
  sudo dnf remove -y "$PKG"
done

# Install base packages
for PKG1 in "${hypr_package[@]}" "${hypr_package_2[@]}" "${copr_packages[@]}"; do
  sudo dnf install -y "$PKG1"
done

echo -ne "
-------------------------------------------------------------------------
                        Install hyprland and sddm
-------------------------------------------------------------------------
"

# Install hyprland
sudo dnf install -y hyprland hypridle hyprlock

# Install sddm
sudo dnf install -y sddm qt6-qt5compat qt6-qtdeclarative qt6-qtsvg

# Activate sddm
sudo systemctl set-default graphical.target
sudo systemctl enable sddm.service

# Ensure hyprland is the default wayland session
sudo mkdir -p /usr/share/wayland-sessions
sudo echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" > /usr/share/wayland-sessions/hyprland.desktop

# Pull gtk engine
sudo dnf install -y gtk-engine-murrine

# Ensure input group exists and put user in it
sudo groupadd input
sudo usermod -aG input "${whoami}"

echo -ne "
-------------------------------------------------------------------------
                        Install ags and shell
-------------------------------------------------------------------------
"

# Pulling ags and dependencies

ags=(
	cmake
    typescript
    nodejs-npm
    meson
    gjs 
    gjs-devel
    gobject-introspection
    gobject-introspection-devel 
    gtk3-devel 
    gtk-layer-shell 
    upower 
    NetworkManager
    pam-devel 
    pulseaudio-libs-devel
    libdbusmenu-gtk3 
    libsoup3
)

# specific tags to download
ags_tag="v1.9.0"

# Installing ags Dependencies
for PKG1 in "${ags[@]}"; do
    sudo dnf install -y "$PKG1"
done

# Clone repository with the specified tag and capture git output into MLOG
if git clone --depth=1 https://github.com/JaKooLit/ags_v1.9.0.git; then
    cd ags_v1.9.0 || exit 1
    npm install
    meson setup build
   if sudo meson install -C build; then
    printf "\nAylur's GTK shell $ags_tag installed successfully.\n"
  else
    echo -e "\nAylur's GTK shell $ags_tag Installation failed\n "
   fi
    # Move logs to Install-Logs directory
    mv ../Install-Logs/ || true
    cd ..
else
    echo -e "\nFailed to download Aylur's GTK shell $ags_tag Please check your connection\n"
    mv ../Install-Logs/ || true
    exit 1
fi

echo -ne "
-------------------------------------------------------------------------
                        Install xdg for gtk and hyprland
-------------------------------------------------------------------------
"

sudo dnf install -y xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

echo -ne "
-------------------------------------------------------------------------
                        Install bluetooth and bluez
-------------------------------------------------------------------------
"

sudo dnf install -y bluez bluez-tools blueman python3-cairo

echo -ne "
-------------------------------------------------------------------------
                        Install and config thunar
-------------------------------------------------------------------------
"

sudo dnf install -y ffmpegthumbnailer Thunar thunar-volman tumbler thunar-archive-plugin xarchiver

xdg-mime default thunar.desktop inode/directory
xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search

echo -ne "
-------------------------------------------------------------------------
                        Install and config zsh
-------------------------------------------------------------------------
"

sudo dnf install -y lsd fzf mercurial zsh util-linux

# Install Oh My Zsh, plugins, and set zsh as default shell
if command -v zsh >/dev/null; then
  printf "Installing Oh My Zsh and plugins ...\n"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then  
    sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended  	       
  else
    echo "Directory .oh-my-zsh already exists. Skipping re-installation."
  fi
  
  # Check if the directories exist before cloning the repositories
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
  else
      echo "Directory zsh-autosuggestions already exists. Cloning Skipped."
  fi

  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  else
      echo "Directory zsh-syntax-highlighting already exists. Cloning Skipped."
  fi
  
  # Check if ~/.zshrc and .zprofile exists, create a backup, and copy the new configuration
  if [ -f "$HOME/.zshrc" ]; then
      cp -b "$HOME/.zshrc" "$HOME/.zshrc-backup" || true
  fi

  if [ -f "$HOME/.zprofile" ]; then
      cp -b "$HOME/.zprofile" "$HOME/.zprofile-backup" || true
  fi

  # Check if the current shell is zsh
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "zsh" ]; then
    printf "Changing default shell to zsh..."

    # Loop to ensure the chsh command succeeds
    while ! chsh -s "$(command -v zsh)"; do
      echo "Authentication failed. Please enter the correct password."
      sleep 1
    done

    printf "Shell changed successfully to zsh"
  else
    echo "Your shell is already set to zsh."
  fi

fi

sudo systemctl reboot now
