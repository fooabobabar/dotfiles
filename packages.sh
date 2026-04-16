#!/bin/bash

sudo chown -R $USER /home/$USER
sudo pacman -S base-devel

git clone https://aur.archlinux.org/yay.git $HOME/Programming/yay
cd $HOME/Programming/yay
makepkg -si
hash -r

yay -S --noconfirm --needed \
     tmux feh fzf bc bind inetutils \
     unzip unrar xorg-xrandr xorg-xinput \
     obs-studio ffmpeg screenkey fuse3 \
     docker docker-compose git ripgrep \
     xclip jq xsel meson sdl imlib2 ttf-dejavu \
     mupdf man-db man-pages gdb cmake claude-code \
     bash-completion librecad python-pip gnu-netcat \
     localsend-bin xorg-xset uv wireshark-cli mpv proton-vpn-cli \
     openrazer-daemon polychromatic slop

mkdir -p ~/.local/share/fonts/

wget -P /home/$USER/Downloads/ https://github.com/be5invis/Iosevka/releases/download/v34.3.0/PkgTTF-Iosevka-34.3.0.zip
wget -P /home/$USER/Downloads/ https://github.com/JetBrains/JetBrainsMono/releases/download/v1.0.2/JetBrainsMono-1.0.2.zip

unzip /home/$USER/Downloads/PkgTTF-Iosevka-30.0.0.zip -d ~/.local/share/fonts/

# docker
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

# boomer
git clone https://github.com/tsoding/boomer.git $HOME/Programming/boomer
cd $HOME/Programming/boomer
wget https://github.com/nim-lang/nimble/releases/download/v0.20.1/nimble-linux_x64.tar.gz
tar -zxvf nimble-linux_x64.tar.gz
./nimble build

# scrot
git clone https://github.com/dreamer/scrot.git $HOME/Programming/scrot
cd $HOME/Programming/scrot
meson setup build
ninja -C build
ninja -C build install

# sowon
git clone https://github.com/tsoding/sowon.git $HOME/Programming/sowon
cd $HOME/Programming/sowon
make

# gf
git clone https://github.com/nakst/gf.git $HOME/Programming/gf
cd $HOME/Programming/gf
./build.sh

# st
git clone https://git.suckless.org/st $HOME/Programming/st
cd $HOME/Programming/st
