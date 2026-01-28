#! /bin/bash

# On vérifie que le script server est invoqué avec un argument
if [ $# -ne 1 ]; then
    echo "Usage: ./$(basename $0) PORT"
    exit 1
fi

# On stocke le port dans la variable PORT
PORT="$1"

# On crée le dossier dans lequel le serveur stocke ses archives
ARCHIVES_DIR="./archives_directory"
mkdir -p "$ARCHIVES_DIR"

# On déclare le tube
FIFO="/tmp/$USER-fifo-$$"

# On crée une fonction de nettoye permettant de détruire le tube quand le serveur est interrompu ou se termine
function cleaning() { rm -f "$FIFO"; }
trap cleaning EXIT

# On crée le tube nommé
[ -e "FIFO" ] || mkfifo "$FIFO"

# On crée la fonction qui permet les interactions entre la sortie standard de netcat et la fonction interaction
function accept-loop() {
    while true; do
	echo -e "\n[LOG] Serveur en attente de requêtes..." >&2
	interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

# On crée la fonction interaction qui reçoit les rêquetes des clients au travers de la sortie standard de netcat et qui fournit les réponses au travers de l'entrée standard de netcat
function interaction() {
    local cmd args
    while true; do
	read cmd args || exit 1
	function="mode-$cmd"
	# On vérifie si la commande correspond à une fonction définie dans le script
	if [ "$(type -t $function)" = "function" ]; then
	    $function $args
	else
	    unknown-mode  $function $args
	fi
    done
}

# Fonction pour les commandes inconnues
function unknown-mode () {
   echo "La commande n'existe pas $cmd $args"
}

# Fonction pour le mode list
function mode-list() {
	echo "[LOG] Mode list selectionné" >&2
	local RESULT=$(ls -A "$ARCHIVES_DIR")

	if [ -z "$RESULT" ]; then
		echo "Aucune archive disponible"
	else
		echo "$RESULT"
	fi
	echo "[LOG] La liste des archives envoyée avec succès" >&2
}

# Fonction pour le mode create
function mode-create(){
	echo "[LOG] Mode create selectionné" >&2
	local ARCHIVE_NAME=$1
	cat > "$ARCHIVES_DIR/$ARCHIVE_NAME"
	if [ -f "$ARCHIVES_DIR/$ARCHIVE_NAME" ]; then
		echo "[LOG] Archive "$ARCHIVE_NAME" crée avec succès" >&2
		echo "Archive "$ARCHIVE_NAME" crée avec succès"
	else
		echo "[LOG] Echec de la création de l'archive "$ARCHIVE_NAME"" >&2
		echo "Echec de la cration de l'archive "$ARCGIVE_NAME""
	fi
}

# Fonction pour le mode extract
function mode-extract(){
	if [ $# -eq 1 ]; then
		echo "[LOG] Mode extract selectionné" >&2
	fi
	local ARCHIVE_NAME=$1
	if [ -f "$ARCHIVES_DIR/$ARCHIVE_NAME" ]; then
		cat "$ARCHIVES_DIR/$ARCHIVE_NAME"
		echo "[LOG] Archive "$ARCHIVE_NAME" extraite avec succès" >&2
	else
		echo "L'archive "$ARCHIVE_NAME" n'existe pas sur le serveur"
		echo "[LOG] L'archive "$ARCHIVE_NAME" n'existe pas sur le serveur" >&2
	fi
}

# Fonction pour le mode browse
function mode-browse() {
	echo "[LOG] Mode browse selectionné" >&2
	mode-extract $1 browse



}

# On lance le serveur au travers de la fonction accept-loop
accept-loop
