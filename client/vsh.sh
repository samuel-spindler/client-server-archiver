#! /bin/bash
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/library"

# On vérifie le nombre d'argument du script
if [ $# -lt 3 ]; then
    echo "Usage: vsh -MODE HOST PORT [nom_archive]"
    exit 1
fi

# On défini les variables
MODE=$1
HOST=$2
PORT=$3
ARCH_NAME=$4

# On met en place la logique des requêtes serveurs en fonction du mode selectionné par l'utilisateur
case "$MODE" in

    "-list")
        # On envoie la requête list au serveur
	# L'option -w 1 stop netcat si aucune données n'est reçue pendant 1 seconde
        echo "list" | nc -w 1 "$HOST" "$PORT"
        ;;

    "-create")
        if [ -z "$ARCH_NAME" ]; then
            echo "Erreur : Nom de l'archive du répertoire courant manquant"
            exit 1
        fi
	# On appel le script qui crée l'archive du répertoire courant et on lui donne le nom $ARCH_NAME
	generate_archive "$ARCH_NAME"

        # On envoie la requête create accompagné de l'archive du répertoire courant au réseau
	(echo "create $ARCH_NAME"; cat "/tmp/$ARCH_NAME") | nc -w 2 "$HOST" "$PORT"
	
        ;;

     "-extract")
        if [ -z "$ARCH_NAME" ]; then
            echo "Erreur: Nom de l'archive recherchée manquant."
       	    exit 1
        fi
        # On envoie la requête de demande d'archive et on la sauvegarde dans un fichier temporaire
        echo "extract $ARCH_NAME" | nc -w 1 "$HOST" "$PORT" > "/tmp/$ARCH_NAME"
	if [ -e "/tmp/$ARCH_NAME" ]; then
	    echo "Archive "$ARCH_NAME" récupérée"
	    # On appel le script de lecture d'archive
	    extract_archive "/tmp/$ARCH_NAME"
     	else
	    echo "Archive "$ARCH_NAME" non récupérée"
	fi
        ;;

    "-browse")
        # On extrait l'archive sur laquelle on veut naviguer
        echo "browse $ARCH_NAME" | nc -w 1 "$HOST" "$PORT" > "/tmp/$ARCH_NAME"
	# On commence la navigation à la racine (début du mini-shell)
	ROOT_NAME=$(grep -m 1 "^directory " "/tmp/$ARCH_NAME" | cut -d' ' -f2)
	if [ -z "$ROOT_NAME" ]; then
		VIRTUAL_PWD=""
	else
		VIRTUAL_PWD="$ROOT_NAME"
	fi
	while true; do
	    display_path="${VIRTUAL_PWD:-/}"
    	    echo -n "vsh:$display_path> "
            read -r line
	    parts=($line)
	    cmd="${parts[0]}"
	    unset 'parts[0]'
	    args=("${parts[@]}")
            case "$cmd" in
       		cd)
           	    do_cd "${args[@]}"
            	;;
        	touch)
            	    do_touch "${args[@]}"
		    sync_to_server
            	;;
        	ls)
            	    do_ls "${args[@]}"
            	;;
       		exit)
            	    break
            	;;
		rm) 
		    do_rm "${args[@]}"
		    sync_to_server
		;;
		cat)
		    do_cat "${args[@]}"
		;;
		mkdir)
		    do_mkdir "${args[0]}"
		    sync_to_server
		;;
       		*)
           	     echo "Commande inconnue"
         	;;
	    esac
	done
    ;;

    *)
        echo "Mode inconnu."
    ;;
esac

