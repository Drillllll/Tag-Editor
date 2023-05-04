#!/bin/bash

Help() {
	echo "Optional arguments:"
	echo "	-h	show help"
	echo "	-v	show version"
	echo "Usage:"
	echo "	edit file's mp3 tags"
	echo "	delete file's mp3 tags"
	echo "	set file's mp3 tags based on filename"
	echo "	set file's mp3 tags for all files in a directory"
	echo "	delete all files' mp3 tags in a directory"
  	echo "	add mp3 tags to all files with given artist tag"

}


Ver() {
	echo "Author           : Oskar Świderski"
	echo "Created On       : 12.04.2022"
	echo "Last Modified By : Oskar Świderski"
	echo "Last Modified On : 27.04.2022"
	echo "Version          : 1.0"
}


PobierzRok() {
	while [[ 1 ]]; do
		R=$(zenity --entry --title "dane" --text "wprowadz rok: ")
		if [[ $R =~ ^[1-9][0-9]{0,3}$ || $? == 1 ]]; then
			break
		else 
			zenity --error --text "niepoprawne dane"
		fi
	done
	echo $R
}


PobierzGatunek() {

	GAT=$(zenity --list --height 300 --width 200 \
		--column="id" --column="gatunek" \
			0 "Blues" \
			4 "Disco" \
			7 "Hip-Hop" \
			8 "Jazz" \
			13 "Pop" \
			15 "Rap" \
			17 "Rock" \
			24 "Soundtrack" \
			32 "Classical" \
			12 "Other")	
	echo $GAT
}


EdytujTagi() {
	FILE=$(zenity --file-selection --file-filter="*.mp3" --title="Wybierz plik mp3")
	RETURN=$?
	if [[ -z "$FILE" ]]; then
		return
	fi

	SCIEZKA=$(dirname "$FILE")
	PLIK=$(basename "$FILE")

	cd "$SCIEZKA"
       	 	while [[ $KOMENDA != 6 ]]; do				
			ARTYSTA=$(mp3info -p %a "$PLIK")
			ALBUM=$(mp3info -p %l "$PLIK")
			TYTUL=$(mp3info -p %t "$PLIK")
			GATUNEK=$(mp3info -p %g "$PLIK")
			ROK=$(mp3info -p %y "$PLIK")	

			KOMENDA=$(zenity --list --height 300 --width 400 \
				--title="MENU" \
				--column="nr" --column="opcja" \
    			1 "Tytuł: $TYTUL" \
			2 "Artysta: $ARTYSTA" \
        		3 "Album: $ALBUM" \
			4 "Gatunek: $GATUNEK" \
			5 "Rok: $ROK" \
			6 "Wyjscie" )

			if [[ $? == 1 ]]; then
				return 
			fi

			case $KOMENDA in
				1) OBECNA=$TYTUL;;
				2) OBECNA=$ARTYSTA;;
				3) OBECNA=$ALBUM;;
			esac
				

			if [[ $KOMENDA != 6 && $KOMENDA != 5 && $KOMENDA != 4 ]]; then
				DANE=$(zenity --entry --title "dane" --text "wprowadz dane: " --entry-text="$OBECNA")
			fi		

			if [[ $KOMENDA == 4 ]]; then
				DANE=$(PobierzGatunek)
			fi

			if [[ $KOMENDA == 5 ]]; then
				DANE=$(PobierzRok)
			fi

			case $KOMENDA in
				1)if [[ -n "$DANE" ]]; then
					id3 -t"$DANE" "$PLIK"
				  fi;;
			    	2)if [[ -n "$DANE" ]]; then
					id3 -a"$DANE" "$PLIK"
				  fi;;
				3)if [[ -n "$DANE" ]]; then	
					id3 -A"$DANE" "$PLIK"
				  fi;;

			 	4)if [[ -n "$DANE" ]]; then
        		        	id3 -g"$DANE" "$PLIK"
				  fi;;

				5)if [[ -n "$DANE" ]]; then
					id3 -y"$DANE" "$PLIK"
				  fi;;
				6)break;;	
			esac			
		done
}


TagiZNazwy() {
	FOLDER=$(zenity --file-selection --directory --title="Wybierz folder")
	if [[ -z "$FOLDER" ]]; then
		return
	fi
	cd "$FOLDER"

	ART_NR=1
	TYT_NR=2
	ALB_NR=3
	OP=$(zenity --list --height 200 --width 400 \
		--title="FORMAT" \
		--column="nr" --column="format" \
		1 "Domyślny format: wykonawca-tytuł-album" \
		2 "Zmien format" )

	if [[ $OP == 2 ]]; then
			while [[ 1 ]]; do
				ART_NR=$(zenity --scale --text="Podaj pozycję Artysty" --min-value 1 --max-value 3 --value 1)
				TYT_NR=$(zenity --scale --text="Podaj pozycję Tytułu" --min-value 1 --max-value 3 --value 1)
		    	ALB_NR=$(zenity --scale --text="Podaj pozycję Albumu" --min-value 1 --max-value 3 --value 1)

				if [[ $ART_NR != $TYT_NR && $ART_NR != $ALB_NR && $TYT_NR != $ALB_NR ]]; then
					break	
				else 
					zenity --error --text "niepoprawne dane"
				fi
			done
	fi
	
	for FILE in *
	do
 	 	if [[ ${FILE: -4} == ".mp3" ]]; then
			BASENAME=$(basename "$FILE" ".mp3")
			ARTYSTA=$(echo "$BASENAME" | cut -d"-" -f$ART_NR)
			TYTUL=$(echo "$BASENAME" | cut -d"-" -f$TYT_NR)
			ALBUM=$(echo "$BASENAME" | cut -d"-" -f$ALB_NR)
			if [[ -n "$ARTYSTA" ]]; then
				id3 -a"$ARTYSTA" "$FILE"
			fi
			if [[ -n "$TYTUL" ]]; then
				id3 -t"$TYTUL" "$FILE"
			fi
			if [[ -n "$ALBUM" ]]; then
				id3 -A"$ALBUM" "$FILE"
			fi
		fi
	done
	#find . -name "*.mp3" -exec basename {} \; -exec id3 -a"dodanyArtysta" {} \;
	#find . -name "*.mp3" -exec basename {} \; -exec cut -d"_" -f1 {} \; 
}

DodajDoWszystkich() {
	FOLDER=$(zenity --file-selection --directory --title="Wybierz folder")
	if [[ -z "$FOLDER" ]]; then
		return
	fi
	cd "$FOLDER"

	OUTPUT=$(zenity --forms --title="Tagi do dodania" \
		--text="Podaj tagi, które zostaną do dane do wszystkich plików w katalogu" \
		--separator="|" \
		--add-entry="Tytuł" \
		--add-entry="Artysta" \
		--add-entry="Album" )
	TYTUL=$(echo $OUTPUT | cut -d"|" -f1)
	ARTYSTA=$(echo $OUTPUT | cut -d"|" -f2)
	ALBUM=$(echo $OUTPUT | cut -d"|" -f3)
	ROK=$(PobierzRok)
	GATUNEK=$(PobierzGatunek)

	for FILE in *
	do
		if [[ ${FILE: -4} == ".mp3" ]]; then
			if [[ -n "$ARTYSTA" ]]; then
				id3 -a"$ARTYSTA" "$FILE"
			fi
			if [[ -n "$TYTUL" ]]; then
				id3 -t"$TYTUL" "$FILE"
			fi
			if [[ -n "$ALBUM" ]]; then
				id3 -A"$ALBUM" "$FILE"
			fi
			if [[ -n "$ROK" ]]; then
    				id3 -y"$ROK" "$FILE"
			fi
    			if [[ -n "$GATUNEK" ]]; then
				id3 -g"$GATUNEK" "$FILE"
			fi
		fi
	done
}

UsunTagi() {
	FILE=$(zenity --file-selection --file-filter="*.mp3" --title="Wybierz plik mp3")
	RETURN=$?
	if [[ -z "$FILE" ]]; then
		return
	fi
	SCIEZKA=$(dirname "$FILE")
	PLIK=$(basename "$FILE")
	cd "$SCIEZKA"

	id3 -l "$PLIK" | zenity --text-info --width 600 --height 300 --title="Tagi przed usunięciem" 

	USUN=$(zenity --list --title="Do usunięcia" --text="Zaznacz Tagi do usunięcia" --checklist \
	       	--column="id"  --column="Name" --width 400 --height 300 \
		1 "Tytul" \
		2 "Artysta" \
	   	3 "Album" \
	   	4 "Rok" \
		5 "Gatunek" )

	ARTYSTA=$(mp3info -p %a "$PLIK")
	ALBUM=$(mp3info -p %l "$PLIK")
	TYTUL=$(mp3info -p %t "$PLIK")
	GATUNEK=$(mp3info -p %g "$PLIK")
	ROK=$(mp3info -p %y "$PLIK")

	id3 -d "$PLIK"

	#Check if a String Contains a Substring
	if ! [[ $USUN == *"Artysta"* ]]; then
		id3 -a"$ARTYSTA" "$PLIK"
	fi

	if !  [[ $USUN == *"Tytul"* ]]; then
		id3 -t"$TYTUL" "$PLIK"
	fi

	if ! [[  $USUN == *"Album"* ]]; then
		id3 -A"$ALBUM" "$PLIK"
	fi

	if ! [[   $USUN == *"Rok"* ]]; then
		id3 -y"$ROK" "$PLIK"
	fi

	if ! [[  $USUN == *"Gatunek"* ]]; then
		id3 -g"$GATUNEK" "$PLIK"
	fi

	id3 -l "$PLIK" | zenity --text-info --width 600 --height 300 --title="Tagi po usunięciu"
}


UsunWszystko() {
	FOLDER=$(zenity --file-selection --directory --title="Wybierz folder")
	if [[ -z "$FOLDER" ]]; then
   	     return
	fi
	cd "$FOLDER"

	for FILE in *
	do 
		if [[ ${FILE: -4} == ".mp3" ]]; then
			id3 -d "$FILE"
		fi
	done
}


DodajDoAutora() {
	FOLDER=$(zenity --file-selection --directory --title="Wybierz folder")
	if [[ -z "$FOLDER" ]]; then
		return
	fi
	cd "$FOLDER"
	
	OUTPUT=$(zenity --forms --title="Autor i tagi do dodania" \
		--text="Podaj artystę. Do wszystkich jego utworów w folderze zostane dodaną podane tagi" \
		--separator="|" \
		--add-entry="Artysta" \
		--add-entry="Tytul" \
		--add-entry="Album" )

	ARTYSTA=$(echo $OUTPUT | cut -d"|" -f1)
	TYTUL=$(echo $OUTPUT | cut -d"|" -f2)
	ALBUM=$(echo $OUTPUT | cut -d"|" -f3)
	ROK=$(PobierzRok)
	GATUNEK=$(PobierzGatunek)

	for FILE in *
	do
		if [[ ${FILE: -4} == ".mp3" ]]; then
			AKT_ART=$(mp3info -p %a "$FILE")
			if [[ $AKT_ART == $ARTYSTA ]]; then
				if [[ -n "$TYTUL" ]]; then
					id3 -t"$TYTUL" "$FILE"
				fi

				if [[ -n "$ALBUM" ]]; then
					id3 -A"$ALBUM" "$FILE"
				fi

				if [[ -n "$ROK" ]]; then
					id3 -y"$ROK" "$FILE"
				fi

				if [[ -n "$GATUNEK" ]]; then
					id3 -g"$GATUNEK" "$FILE"
				fi
			fi
		fi
	done
}

#hv znaczy ze opcje h i v są poprawne
while getopts ":hv" OPT; do
	case $OPT in
	h) Help;;
	v) Ver;;
	esac
done

#optind is the index of the next element to be processed in argv (tak jakby ilosc wczytanych opcji)
if [[ $OPTIND == 1 ]]; then
	while [[ $KOMENDA != 1 ]]; do
		KOMENDA=$(zenity --list --height 300 --width 400 \
			--title="MENU" \
			--column="nr" --column="opcja" \
			1 "Wyjście" \
			2 "Edycja tagów pliku" \
			3 "Usuwanie tagów pliku" \
			4 "Ustawianie tagów na podstawie nazwy" \
			5 "Dodawanie tagów do wszystkich plików w katalogu" \
			6 "Usuwanie tagów z wszystkich plików" \
		       	7 "Dodawanie tagów do plików z tagiem artysty ")
	
		case $KOMENDA in
			1) break;;
			2) EdytujTagi;;
			3) UsunTagi;;
			4) TagiZNazwy;;
			5) DodajDoWszystkich;;
			6) UsunWszystko;;
			7) DodajDoAutora;;	
		esac
	done
fi
