# Projet serveur d'archive en Bash

Ce projet consiste en une solution **Client-Serveur** robuste développée intégralement en **Bash**. Il permet de générer des archives personnalisées, de les stocker sur un serveur distant et de les manipuler via un shell virtuel interactif sans extraction préalable.

## Équipe du projet

Ce projet a été réalisé en équipe dans le cadre de l'UE LO14 à l'UTT en première année de spécialisation Réseaux & Télécommunications:
- **Samuel SPINDLER** : Architecture réseau, protocoles de communications et implémentation des modes d'interactions.
- **Max DIECHTIAREF--HUCK** : Gestion du format archive et implémentation du mini-shell.

## Fonctionnalités Clés

- **Format d'Archive** : Structure optimisée avec un index de saut, un Header (métadonnées) et un Body (données brutes).
- **Client vsh** : Un outil polyvalent supportant les modes `-create`, `-list`, `-extract` et `-browse`.
- **Navigation Virtuelle** : Un mini-shell (`vsh -browse`) permettant les commandes `ls`, `cd`, `pwd`, `cat`, `touch`, `mkdir` et `rm` directement dans l'archive.
- **Gestion des Droits** : Sauvegarde et restauration fidèle des permissions et de l'arborescence.
- **Communication Réseau** : Protocole basé sur `netcat` avec gestion de flux bidirectionnels via tubes nommés (FIFO).

## Concepts Techniques Avancés

- **Système d'indexation par Offsets** : Pour optimiser les performances, l'archive utilise des pointeurs (lignes/caractères) permettant d'accéder directement au corps d'un fichier (Body) à partir de son entrée dans l'en-tête (Header).
- **Récursion et Gestion d'Arborescence** : Algorithme de parcours en profondeur capable de capturer des structures complexes, incluant les dossiers vides et les fichiers cachés.
- **Restauration de l'Environnement** : Le mode `-extract` ne se contente pas de copier les données, il reconstruit l'arborescence originale et applique les permissions Unix (`chmod`) récupérées du serveur.
- **Flux Réseau Bidirectionnels** : Utilisation de tubes nommés (FIFO) sur le serveur pour séparer le flux de commande du flux de données, permettant une interactivité fluide dans le mode `browse`.

## Architecture du Projet

Le système est découpé en trois composants principaux :

1. **`server.sh`** : Serveur écoutant sur un port TCP, gérant le stockage et la redirection des requêtes.
2. **`vsh.sh`** : Interface client gérant les interactions utilisateur et le transfert de flux.
3. **`library.sh`** : Bibliothèque de fonctions.

## Structure de l'Archive

L'archive utilise un système d'indexation en première ligne pour optimiser les performances de lecture :

```text
2:15                  <-- Index (Début Header : Début Body)
directory projet/     <-- Marqueur de répertoire
notes.txt -rw-r--r-- 12 1 2  <-- Fichier (Nom | Droits | Taille | Offset | Lignes)
@                     <-- Fin de bloc répertoire
Contenu du fichier... <-- Section Body (Données brutes)
```

## Installation et Utilisation

### Prérequis
- Système Linux/Unix (Projet uniquement testé sur Kali Linux).
- Utilitaire `netcat` (`nc`) installé sur le client et le serveur.

### Étape 1 : Préparation
Assurez-vous que tous les scripts disposent des droits d'exécution nécessaires :

```bash
chmod +x vsh server
```

### Étape 2 : Lancement du Serveur
Le serveur doit être démarré en premier. Il créera automatiquement un répertoire de stockage nommé `archives_directory` pour centraliser les données.

```bash
./server 8080
```

### Étape 3 : Utilisation du Client (vsh.sh)
Le client communique avec le serveur via `netcat` en utilisant la syntaxe suivante :

| Action | Commande |
| :--- | :--- |
| **Lister** les archives | `./vsh -list localhost 8080` |
| **Créer** une archive | `./vsh -create localhost 8080 archive.test` |
| **Extraire** une archive | `./vsh -extract localhost 8080 archive.test` |
| **Naviguer** dans une archive | `./vsh -browse localhost 8080 archive.test` |
