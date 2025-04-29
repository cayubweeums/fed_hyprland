#!/bin/bash

dir=$(pwd)

echo -ne "
-------------------------------------------------------------------------
                            Config DNF
-------------------------------------------------------------------------
"
sleep 3

echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf &&
echo "minrate=10k" | sudo tee -a /etc/dnf/dnf.conf &&
echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf &&
echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf

echo -ne "
-------------------------------------------------------------------------
                        Install Basic Packages
-------------------------------------------------------------------------
"
sleep 3

sudo dnf -y upgrade --refresh

printf "Installing basic packages"

# packages neeeded
basics=(
    wget
    unzip
    rsync
    figlet
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
  docker-compose
  caca-utils
  imagemagick
  ffmpeg
)

# Install base packages
for PKG1 in "${personal_package[@]}" "${basics[@]}"; do
  sudo dnf install -y "$PKG1"
done

echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
sudo yum install -y gum

echo -ne "
-------------------------------------------------------------------------
                        Enable solopasha/hyprland
-------------------------------------------------------------------------
"
sleep 3

sudo dnf copr enable -y solopasha/hyprland

sudo dnf update

echo -ne "
-------------------------------------------------------------------------
                        Install hyprland packages
-------------------------------------------------------------------------
"
sleep 3

hyprland_packages=(
    "hyprland"
    "waybar"
    "rofi-wayland"
    "alacritty"
    "dunst"
    "Thunar"
    "xdg-desktop-portal-hyprland"
    "qt5-qtwayland"
    "qt6-qtwayland"
    "hyprpaper"
    "hyprlock"
    "firefox"
    "fontawesome-6-free-fonts"
    "vim"
    "vim-enhanced"
    "python3-pip"
    "fastfetch"
    "mozilla-fira-sans-fonts"
    "fira-code-fonts"
    "wlogout"
    "python3-gobject" 
    "gtk4"
    "sddm"
)

# Install hyprland packages
for PKG1 in "${hyprland_packages[@]}"; do
  sudo dnf install -y "$PKG1"
done

echo -ne "
-------------------------------------------------------------------------
                        Config sddm
-------------------------------------------------------------------------
"
sleep 3

sudo systemctl set-default graphical.target

sudo systemctl enable sddm.service

mkdir -p /usr/share/wayland-sessions

echo -e "[Desktop Entry]\nName=Hyprland\nComment=An intelligent dynamic tiling Wayland compositor\nExec=Hyprland\nType=Application" > /usr/share/wayland-sessions/hyprland.desktop

echo -ne "
-------------------------------------------------------------------------
                        Install and config zsh
-------------------------------------------------------------------------
"
sleep 3

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

  echo "run chsh -s $(which zsh) to change shell to zsh after the reboot"
  sleep 5

fi

echo -ne "
-------------------------------------------------------------------------
                        Copying configs
-------------------------------------------------------------------------
"
sleep 3

rsync -avhp -I configs/ ~/

echo -ne "
-------------------------------------------------------------------------
                        Rebooting in 5s
-------------------------------------------------------------------------
"
sleep 5

sudo systemctl reboot now