#!/bin/bash
sudo apt update && sudo apt install git
git clone https://github.com/veyselerden/openbox-dotfiles.git
cd openbox-dotfiles
sudo apt modernize-sources -y
echo "Şimdi source list'i düzenle"
sleep 3
sudo nano /etc/apt/sources.list.d/debian.sources
cp ./apt-preferences /etc/apt/preferences.d/
sudo apt update
sudo apt full-upgrade --auto-remove extrepo
sudo extrepo enable xlibre
echo "Şimdi 'Uris' kısmını düzelt"
sleep 1
sudo nano /etc/apt/sources.list.d/extrepo_xlibre.sources
sudo apt update
sudo apt install openbox tint2 volumeicon-alsa pipewire pipewire-pulse pipewire-alsa wireplumber dbus dbus-x11 flatpak xlibre connman connman-gtk fonts-firacode fonts-noto dmz-cursor-theme greybird-gtk-theme elementary-xfce-icon-theme gmrun lxterminal pcmanfm xarchiver 7zip lxtask lxrandr lxappearance-obconf lxappearance
cp ./dotfiles/* ~/.config/
sudo apt install build-essential libpam0g-dev libxcb-xkb-dev xauth brightnessctl
cd ~
git clone https://codeberg.org/fairyglade/ly.git
cd ly
zig build
sudo zig build installexe -Dinit_system=systemd
sudo systemctl enable ly@tty2.service
sudo systemctl disable getty@tty2.service
sudo apt purge vim* git* build-essential libpam0g-dev libxcb-xkb-dev libc6-dev dpkg-dev
cd ~
sudo cp ./openbox-dotfiles/fonts/* /usr/share/fonts/
sudo fc-cache -f
sudo rm -rf ./openbox-dotfiles ./ly
echo "Kurulum tamamlandı, 10 saniye sonra yeniden başlatılıyor..."
sleep 10
systemctl reboot