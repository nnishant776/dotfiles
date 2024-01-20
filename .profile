# Aliases
alias tmux='tmux -u'
alias config='/usr/bin/git --git-dir="$HOME/.dotfiles" --work-tree=$HOME'
alias download='aria2c -x 4 -c --file-allocation=falloc'

# Exports
export LANG=en_US.UTF8
export EDITOR='nvim'
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND="wayland,x11"
export MOZ_ENABLE_WAYLAND=1

# Bash functions
vagrant(){
    podman run -it --rm \
        -e LIBVIRT_DEFAULT_URI \
        -v /var/run/libvirt/:/var/run/libvirt/ \
        -v ~/.vagrant.d:/.vagrant.d \
        -v $(realpath "${PWD}"):${PWD} \
        -w "${PWD}" \
        --network host \
        vagrantlibvirt/vagrant-libvirt:latest \
        vagrant $@
}

tgdm() {
    local current_color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
    if [ "$current_color_scheme" = "'prefer-light'" ] || [ "$current_color_scheme" = "'default'" ] ;then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
        gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors-light'
        ln -sf ~/.config/waybar/waybar-dark.config ~/.config/waybar/config
        ln -sf ~/.config/waybar/style-dark.css ~/.config/waybar/style.css
        ln -sf ~/.config/sway/sway-dark.config ~/.config/sway/config
    elif [ "$current_color_scheme" = "'prefer-dark'" ];then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
        gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors'
        ln -sf ~/.config/waybar/waybar-light.config ~/.config/waybar/config
        ln -sf ~/.config/waybar/style-light.css ~/.config/waybar/style.css
        ln -sf ~/.config/sway/sway-light.config ~/.config/sway/config
    fi
}
