#!/bin/bash

###############################################################################
# Openbox Dynamic Pipe-Menu Script
# ---------------------------------------------------------------------------
# Description:  A lightweight, multi-language supporting dynamic pipe-menu.
#               Features: XDG Categorization, Flatpak support, duplicate 
#               prevention, and smart [Desktop Entry] parsing.
#
# Created by:   Gemini (Google AI)
#               Tailored and refined for a custom Openbox setup.
#
# Date:         2025
###############################################################################

# 1. Detect system language
SLANG=$(echo "$LANG" | cut -c1-2)

# 2. Categories and Translations
UTI="Accessories"; SET="Settings"; DEV="Development"; GRA="Graphics"
NET="Network"; MED="Multimedia"; OFF="Office"; GAM="Games"; SYS="System"

if [ "$SLANG" = "tr" ]; then
    UTI="Araçlar"; SET="Ayarlar"; DEV="Geliştirme"; GRA="Grafik"
    NET="İnternet"; MED="Multimedya"; OFF="Ofis"; GAM="Oyunlar"; SYS="Sistem"
fi

# 3. Directories (Priority Order: Local > Flatpak > System)
CAT_DEFS="Utility:$UTI Settings:$SET Development:$DEV Graphics:$GRA Network:$NET AudioVideo:$MED Office:$OFF Game:$GAM System:$SYS"
APP_DIRS="$HOME/.local/share/applications $HOME/.local/share/flatpak/exports/share/applications /var/lib/flatpak/exports/share/applications /usr/share/applications"

echo "<openbox_pipe_menu>"

TMP_LIST=$(mktemp)
PROCESSED_LIST=$(mktemp)
FORBIDDEN_LIST=$(mktemp)

# 4. Scanning with NoDisplay override logic
for dir in $APP_DIRS; do
    if [ -d "$dir" ]; then
        for file in "$dir"/*.desktop; do
            [ -e "$file" ] || continue
            fname=$(basename "$file")
            
            # Eğer bu dosya ismi daha önce işlenmediyse veya yasaklanmadıysa bak
            if ! grep -q "^$fname$" "$PROCESSED_LIST" 2>/dev/null && ! grep -q "^$fname$" "$FORBIDDEN_LIST" 2>/dev/null; then
                if grep -q "NoDisplay=true" "$file"; then
                    # Eğer NoDisplay=true ise bu ismi yasaklı listesine ekle (Sistem kopyasını da engelle)
                    echo "$fname" >> "$FORBIDDEN_LIST"
                else
                    # Değilse tarama listesine ekle
                    echo "$file" >> "$TMP_LIST"
                    echo "$fname" >> "$PROCESSED_LIST"
                fi
            fi
        done
    fi
done

# PROCESSED_LIST'i temizle ki kategoriler arası mükerrerlik kontrolü için taze kalsın
> "$PROCESSED_LIST"

# 5. Generate Menu XML
for entry in $CAT_DEFS; do
    cat_key=${entry%:*}
    cat_label=${entry#*:}
    apps_list=""
    
    while read -r app_path; do
        fname=$(basename "$app_path")
        
        if grep -q "Categories=.*$cat_key" "$app_path" 2>/dev/null; then
            if ! grep -q "^$fname$" "$PROCESSED_LIST" 2>/dev/null; then
                
                MAIN_SECTION=$(sed -n '/^\[Desktop Entry\]/,/^\[/p' "$app_path" | grep -v '^\[.*\]' | grep -v '^$')
                
                NAME=$(echo "$MAIN_SECTION" | grep "^Name\[$SLANG\]=" | head -1 | cut -d= -f2-)
                [ -z "$NAME" ] && NAME=$(echo "$MAIN_SECTION" | grep "^Name=" | head -1 | cut -d= -f2-)
                
                EXEC=$(echo "$MAIN_SECTION" | grep "^Exec=" | head -1 | cut -d= -f2- | sed 's/%.//g' | tr -d '"' | sed 's/@//g')
                
                case "$app_path" in *flatpak*) NAME="$NAME (Flatpak)" ;; esac
                
                if [ -n "$NAME" ]; then
                    apps_list="${apps_list}${NAME}|${EXEC}"$'\n'
                    echo "$fname" >> "$PROCESSED_LIST"
                fi
            fi
        fi
    done < "$TMP_LIST"

    if [ -n "$apps_list" ]; then
        printf '  <menu id="cat-%s" label="%s">\n' "$cat_key" "$cat_label"
        echo "$apps_list" | sort -f | while IFS="|" read -r name exec; do
            [ -z "$name" ] && continue
            S_NAME=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            S_EXEC=$(echo "$exec" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            printf '    <item label="%s">\n' "$S_NAME"
            printf '      <action name="Execute"><command>%s</command></action>\n' "$S_EXEC"
            printf '    </item>\n'
        done
        echo "  </menu>"
    fi
done

rm -f "$TMP_LIST" "$PROCESSED_LIST" "$FORBIDDEN_LIST"
echo "</openbox_pipe_menu>"