#!/bin/bash

# Hata durumunda dur, tanımlanmamış değişkeni hata say, pipe hatalarını yakala
set -euo pipefail

echo "--- Debian Yapılandırması Başlıyor ---"

# 1. Contrib ve Non-Free Depolarını Etkinleştirme
echo "0. Git kuruluyor.."
sudo apt install -y git

echo "1. Depolar güncelleniyor (contrib non-free)..."
sudo apt modernize-sources
echo "Şimdi source list'i düzenle"
sleep 3
sudo nano /etc/apt/sources.list.d/debian.sources

# 2. Trixie-Backports Deposunu Ekleme
echo "2. Trixie-backports ekleniyor..."
BACKPORTS_ENTRY="deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware"
if ! grep -q "trixie-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "$BACKPORTS_ENTRY" | sudo tee /etc/apt/sources.list.d/trixie-backports.list
fi

# 3. APT Preferences (Pinning) Ayarları
# linux-* hariç her şeyi backports'tan çek, linux-* paketlerini normal depoda tut
echo "3. APT Preferences yapılandırılıyor..."
sudo tee /etc/apt/preferences.d/backports-policy <<EOF
Package: linux-*
Pin: release n=trixie-backports
Pin-Priority: -1

Package: *
Pin: release n=trixie-backports
Pin-Priority: 900
EOF

sudo apt update
sudo apt full-upgrade -y --auto-remove

# 4. Extrepo Kurulumu ve XLibre Aktivasyonu
echo "4. Extrepo üzerinden XLibre aktif ediliyor..."
sudo apt install -y extrepo
sudo extrepo enable xlibre

# 5. Extrepo URIs Hatası Düzeltme
# 'Uris' ifadesini 'URIs' olarak değiştirir (case-sensitive)
echo "5. Extrepo source dosyası düzeltiliyor (Uris -> URIs)..."
SOURCES_FILE="/etc/apt/sources.list.d/extrepo_xlibre.sources"
if [ -f "$SOURCES_FILE" ]; then
    sudo sed -i 's/^Uris:/URIs:/' "$SOURCES_FILE"
    sudo apt update
else
    echo "Hata: $SOURCES_FILE bulunamadı!"
    exit 1
fi

# 6. Ek Paket Kurulumları (Buraya istediğin paketleri ekleyebilirsin)
echo "6. Ek paketler kuruluyor..."
sudo apt install -y xlibre openbox tint2 volumeicon-alsa pipewire pipewire-pulse pipewire-alsa wireplumber dbus dbus-x11 flatpak xlibre connman connman-gtk fonts-firacode fonts-noto dmz-cursor-theme greybird-gtk-theme elementary-xfce-icon-theme gmrun lxterminal pcmanfm xarchiver 7zip lxtask lxrandr lxappearance-obconf lxappearance
sudo apt update

# 7. Ly Display Manager Kurulumu (Git üzerinden)
echo "7. Ly kurulumu başlıyor..."
sudo apt install -y build-essential libpam0g-dev libxcb-xkb-dev xauth brightnessctl
cd /tmp
# Eğer klasör varsa temizle
rm -rf ly
git clone --recurse-submodules https://github.com/fairyglade/ly
cd ly
zig build
sudo zig build installexe -Dinit_system=systemd
sudo systemctl enable ly@tty2.service
sudo systemctl disable getty@tty2.service

echo "--- İşlem Başarıyla Tamamlandı! ---"
