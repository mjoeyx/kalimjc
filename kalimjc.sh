#!/data/data/com.termux/files/usr/bin/bash -e
# Modified by Mjoeyx
# Install kali nethunter di termux tanpa root dan tanpa error
# Alat ini mungkin menyelesaikan kesalahan seperti kex server, dpkg, chroot, line 361
# 20/04/2025
#!/data/data/com.termux/files/usr/bin/bash -e

VERSION=2024091801
BASE_URL=https://image-nethunter.kali.org/nethunter-fs/kali-daily
USERNAME=kali



function unsupported_arch() {
    printf "${red}"
    echo "[*] Architecture Tidak didukung\n\n"
    printf "${reset}"
    exit
}

function ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ajukan pertanyaan
        printf "${light_cyan}\n[?] "
        read -p "$1 [$prompt] " REPLY

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        printf "${reset}"

        # Periksa balasan valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

function get_arch() {
    printf "${blue}[*] Cek Perangkat architecture ..."
    case $(getprop ro.product.cpu.abi) in
        arm64-v8a)
            SYS_ARCH=arm64
            ;;
        armeabi|armeabi-v7a)
            SYS_ARCH=armhf
            ;;
        *)
            unsupported_arch
            ;;
    esac
}

function set_strings() {
    echo \
    && echo "" 
    ####
    if [[ ${SYS_ARCH} == "arm64" ]];
    then
        echo "[1] NetHunter ARM64 (full)"
        echo "[2] NetHunter ARM64 (minimal)"
        echo "[3] NetHunter ARM64 (nano)"
        read -p "Pilih yang ingin Anda install: " wimg
        if (( $wimg == "1" ));
        then
            wimg="full"
        elif (( $wimg == "2" ));
        then
            wimg="minimal"
        elif (( $wimg == "3" ));
        then
            wimg="nano"
        else
            wimg="full"
        fi
    elif [[ ${SYS_ARCH} == "armhf" ]];
    then
        echo "[1] NetHunter ARMhf (full)"
        echo "[2] NetHunter ARMhf (minimal)"
        echo "[3] NetHunter ARMhf (nano)"
        read -p "Pilih yang ingin Anda install: " wimg
        if [[ "$wimg" == "1" ]]; then
            wimg="full"
        elif [[ "$wimg" == "2" ]]; then
            wimg="minimal"
        elif [[ "$wimg" == "3" ]]; then
            wimg="nano"
        else
            wimg="full"
        fi
    fi
    ####


    CHROOT=kali-${SYS_ARCH}
    IMAGE_NAME=kali-nethunter-daily-dev-rootfs-${wimg}-${SYS_ARCH}.tar.xz
    SHA_NAME=${IMAGE_NAME}.sha512sum
}    

function prepare_fs() {
    unset KEEP_CHROOT
    if [ -d ${CHROOT} ]; then
        if ask "ditemukan Direktori rootfs. apakah Anda ingin Hapus dan buat yang baru?" "N"; then
            rm -rf ${CHROOT}
        else
            KEEP_CHROOT=1
        fi
    fi
} 

function cleanup() {
    if [ -f "${IMAGE_NAME}" ]; then
        if ask "Hapus file rootfs yang diunduh?" "N"; then
        if [ -f "${IMAGE_NAME}" ]; then
                rm -f "${IMAGE_NAME}"
        fi
        if [ -f "${SHA_NAME}" ]; then
                rm -f "${SHA_NAME}"
        fi
        fi
    fi
} 

function check_dependencies() {
    printf "${blue}\n[*] Memeriksa dependensi paket...${reset}\n"
    ## Workaround for termux-app issue #1283 (https://github.com/termux/termux-app/issues/1283)
    ##apt update -y &> /dev/null
    apt-get update -y &> /dev/null || apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade -y &> /dev/null

    for i in proot tar axel; do
        if [ -e "$PREFIX"/bin/$i ]; then
            echo "  $i is OK"
        else
            printf "Menginstal ${i}...\n"
            apt install -y $i || {
                printf "${red}ERROR: Gagal menginstall paket.\n Keluar.\n${reset}"
            exit
            }
        fi
    done
    apt upgrade -y
}


function get_url() {
    ROOTFS_URL="${BASE_URL}/${IMAGE_NAME}"
    SHA_URL="${BASE_URL}/${SHA_NAME}"
}

function get_rootfs() {
    unset KEEP_IMAGE
    if [ -f "${IMAGE_NAME}" ]; then
        if ask "ditemukan File gambar. apakah Anda ingin Hapus dan unduh yang baru?" "N"; then
            rm -f "${IMAGE_NAME}"
        else
            printf "${yellow}[!] Menggunakan arsip rootfs yang ada${reset}\n"
            KEEP_IMAGE=1
            return
        fi
    fi
    printf "${blue}[*] Mengunduh rootfs...${reset}\n\n"
    get_url
    wget --continue "${ROOTFS_URL}"
}

function check_sha_url() {
    if ! curl --head --silent --fail "${SHA_URL}" > /dev/null; then
        echo "[!] SHA_URL tidak ada atau tidak terjangkau"
        return 1
    fi
    return 0
}

function verify_sha() {
    if [ -z $KEEP_IMAGE ]; then
        printf "\n${blue}[*] Memverifikasi integritas rootfs....${reset}\n\n"
        if [ -f "${SHA_NAME}" ]; then
            sha512sum -c "$SHA_NAME" || {
                printf "${red} Rootfs rusak. Harap jalankan penginstal ini lagi atau unduh file secara manual\n${reset}"
                exit 1
            }
        else
            echo "[!] SHA file tidak ditemukan. Lewati verifikasi..."    
        fi    
    fi
}

function get_sha() {
    if [ -z $KEEP_IMAGE ]; then
        printf "\n${blue}[*] Mendapatkan SHA ... ${reset}\n\n"
        get_url
        if [ -f "${SHA_NAME}" ]; then
            rm -f "${SHA_NAME}"
        fi        
        if check_sha_url; then
            echo "[+] SHA_URL ditemukan. Lanjutkan dengan unduhan..."
            wget --continue "${SHA_URL}"
            verify_sha
        else
            echo "[!] SHA_URL tidak ditemukan. Lewati unduhan."
        fi
    fi        
}

function extract_rootfs() {
    if [ -z $KEEP_CHROOT ]; then
        printf "\n${blue}[*] Mengekstraksi rootfs... ${reset}\n\n"
        proot --link2symlink tar -xf "$IMAGE_NAME" 2> /dev/null || :
    else        
        printf "${yellow}[!] Menggunakan direktori rootfs yang ada${reset}\n"
    fi
}


function create_launcher() {
    NH_LAUNCHER=${PREFIX}/bin/nethunter
    NH_SHORTCUT=${PREFIX}/bin/nh
    cat > "$NH_LAUNCHER" <<- EOF
#!/data/data/com.termux/files/usr/bin/bash -e
cd \${HOME}
## termux-exec sets LD_PRELOAD Jadi mari kita lepas sebelum melanjutkan
unset LD_PRELOAD
## Solusi untuk LibreOffice, juga perlu mengikatkan dengan yang palsu atau fake /proc/version
if [ ! -f $CHROOT/root/.version ]; then
    touch $CHROOT/root/.version
fi

## Pengguna default adalah "kali"
user="$USERNAME"
home="/home/\$user"
start="sudo -u kali /bin/bash"

## NH dapat diluncurkan sebagai root dengan "-r" cmd atribut
## Periksa juga apakah pengguna Kali ada, jika tidak mulai sebagai root grep -q "kali" ${CHROOT}/etc/passwd; then
    KALIUSR="1";
else
    KALIUSR="0";
fi
if [[ \$KALIUSR == "0" || ("\$#" != "0" && ("\$1" == "-r" || "\$1" == "-R")) ]];then
    user="root"
    home="/\$user"
    start="/bin/bash --login"
    if [[ "\$#" != "0" && ("\$1" == "-r" || "\$1" == "-R") ]];then
        shift
    fi
fi

cmdline="proot \\
        --link2symlink \\
        -0 \\
        -r $CHROOT \\
        -b /dev \\
        -b /proc \\
        -b /sdcard \\
        -b $CHROOT\$home:/dev/shm \\
        -w \$home \\
           /usr/bin/env -i \\
           HOME=\$home \\
           PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \\
           TERM=\$TERM \\
           LANG=C.UTF-8 \\
           \$start"

cmd="\$@"
if [ "\$#" == "0" ];then
    exec \$cmdline
else
    \$cmdline -c "\$cmd"
fi
EOF

    chmod 700 "$NH_LAUNCHER"
    if [ -L "${NH_SHORTCUT}" ]; then
        rm -f "${NH_SHORTCUT}"
    fi
    if [ ! -f "${NH_SHORTCUT}" ]; then
        ln -s "${NH_LAUNCHER}" "${NH_SHORTCUT}" >/dev/null
    fi
   
}

function check_kex() {
    if [ "$wimg" = "nano" ] || [ "$wimg" = "minimal" ]; then
        nh sudo apt update && nh sudo apt install -y tightvncserver kali-desktop-xfce
    fi
}
function create_kex_launcher() {
    KEX_LAUNCHER=${CHROOT}/usr/bin/kex
    cat > $KEX_LAUNCHER <<- EOF
#!/bin/bash

function start-kex() {
    if [ ! -f ~/.vnc/passwd ]; then
        passwd-kex
    fi
    USR=\$(whoami)
    if [ \$USR == "root" ]; then
        SCREEN=":2"
    else
        SCREEN=":1"
    fi 
    export MOZ_FAKE_NO_SANDBOX=1; export HOME=\${HOME}; export USER=\${USR}; LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libgcc_s.so.1 nohup vncserver \$SCREEN >/dev/null 2>&1 </dev/null
    starting_kex=1
    return 0
}

function stop-kex() {
    vncserver -kill :1 | sed s/"Xtigervnc"/"NetHunter KeX"/
    vncserver -kill :2 | sed s/"Xtigervnc"/"NetHunter KeX"/
    return $?
}

function passwd-kex() {
    vncpasswd
    return $?
}

function status-kex() {
    sessions=\$(vncserver -list | sed s/"TigerVNC"/"NetHunter KeX"/)
    if [[ \$sessions == *"590"* ]]; then
        printf "\n\${sessions}\n"
        printf "\nAnda dapat menggunakan klien KeX untuk terhubung ke salah satu tampilan ini.\n\n"
    else
        if [ ! -z \$starting_kex ]; then
            printf '\nError saat memulai KeX server.\nHarap coba "nethunter kex kill" atau restart sesi termux Anda dan cobalagi.\n\n'
        fi
    fi
    return 0
}

function kill-kex() {
    pkill Xtigervnc
    return \$?
}

case \$1 in
    start)
        start-kex
        ;;
    stop)
        stop-kex
        ;;
    status)
        status-kex
        ;;
    passwd)
        passwd-kex
        ;;
    kill)
        kill-kex
        ;;
    *)
        stop-kex
        start-kex
        status-kex
        ;;
esac
EOF

    chmod 700 $KEX_LAUNCHER
}

function fix_profile_bash() {
    ## Prevent attempt to create links in read only filesystem
    if [ -f ${CHROOT}/root/.bash_profile ]; then
        sed -i '/if/,/fi/d' "${CHROOT}/root/.bash_profile"
    fi
}

function fix_resolv_conf() {
    ## We don't have systemd so let's use static entries for Quad9 DNS servers
    echo "nameserver 9.9.9.9" > $CHROOT/etc/resolv.conf
    echo "nameserver 149.112.112.112" >> $CHROOT/etc/resolv.conf
}

function fix_sudo() {
    ## fix sudo & su on start
    chmod +s $CHROOT/usr/bin/sudo
    chmod +s $CHROOT/usr/bin/su
    echo "kali    ALL=(ALL:ALL) ALL" > $CHROOT/etc/sudoers.d/kali

    # https://bugzilla.redhat.com/show_bug.cgi?id=1773148
    echo "Set disable_coredump false" > $CHROOT/etc/sudo.conf
}

function fix_uid() {
    ## Change kali uid and gid to match that of the termux user
    USRID=$(id -u)
    GRPID=$(id -g)
    nh -r usermod -u "$USRID" kali 2>/dev/null
    nh -r groupmod -g "$GRPID" kali 2>/dev/null
}

function print_banner() {
     printf "${blue}##################################################\n"
    printf "${blue}##                                              ##\n"
    printf "${green}##  88      a8P         db        88        88  ##\n"
    printf "${blue}##  88    .88'         d88b       88        88  ##\n"
    printf "${red}##  88   88'          d8''8b      88        88  ##\n"
    printf "${red}##  88 d88           d8'  '8b     88        88  ##\n"
    printf "${red}##  8888'88.        d8YaaaaY8b    88        88  ##\n"
    printf "${red}##  88P   Y8b      d8''''''''8b   88        88  ##\n"
    printf "${blue}##  88     '88.   d8'        '8b  88        88  ##\n"
    printf "${red}##  88       Y8b d8'          '8b 888888888 88  ##\n"
    printf "${blue}##                                              ##\n"
    printf "${blue}####  ############# MJC-NetHunter ####################${reset}\n\n"
    printf "${red} ++++++ SCRIPT Modified by Mjoeyx  +++++\n"
    printf "${green}[*]»» Telegram :- https://t.me/mj0ey\n"
}


##################################
##              Main            ##

# Add some colours
red='\033[1;31m'
green='\033[1;32m'
yellow='\033[1;33m'
blue='\033[1;34m'
light_cyan='\033[1;96m'
reset='\033[0m'

cd "$HOME"
print_banner
get_arch
set_strings
prepare_fs
check_dependencies
get_rootfs
get_sha
extract_rootfs
create_launcher
cleanup

printf "\n${blue}[*] Mengkonfigurasi MJC-NetHunter untuk Termux ...\n"
fix_profile_bash
fix_resolv_conf
fix_sudo
check_kex
create_kex_launcher
fix_uid

print_banner
printf "${green}[=] Install Kali MJC-NetHunter untuk Termux installed Berhasil${reset}\n\n"
printf "${green}[+] memulai Kali MJC-NetHunter, Ketik:${reset}\n"
printf "${green}[+] nethunter             # Memulai NetHunter CLI${reset}\n"
printf "${green}[+] nethunter kex passwd  # Mengatur KeX password${reset}\n"
printf "${green}[+] nethunter kex &       # Memulai NetHunter GUI${reset}\n"
printf "${green}[+] nethunter kex stop    # Berhenti NetHunter GUI${reset}\n"
#printf "${green}[+] nethunter kex <command> # Run command in NetHunter env${reset}\n"
printf "${green}[+] nethunter -r          # Jalankan NetHunter sebagai root${reset}\n"
#printf "${green}[+] nethunter -r kex passwd  # To set the KeX password for root${reset}\n"
#printf "${green}[+] nethunter kex &       # To start NetHunter GUI as root${reset}\n"
#printf "${green}[+] nethunter kex stop    # To stop NetHunter GUI root session${reset}\n"
#printf "${green}[+] nethunter -r kex kill # To stop all NetHunter GUI sessions${reset}\n"
#printf "${green}[+] nethunter -r kex <command> # Run command in NetHunter env as root${reset}\n"
printf "${green}[+] nh                    # Pintasan untuk nethunter${reset}\n\n"









