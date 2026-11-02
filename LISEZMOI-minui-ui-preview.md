# Prévisualisations MinUI Legacy avec annotations `res/`

Ce script prend les **véritables ressources de ton dépôt local** :

`coffeecore/MinUI-Legacy-Trimui-Model-S`, branche `picoarch`, répertoire `res/`.

Il suit la disposition principale de `src/MinUI/main.c` : affichage en **320 × 240**, logo à `(10,10)`, lignes en `y=38` espacées de `32`, au plus `5` lignes visibles, barre du bas en `y=202`, et polices `BPreplayBold.otf` en 16 et 14 pixels.

## Installation

Sur Kubuntu :

```bash
sudo apt install python3-pil
```

## Exécution

Depuis la racine du projet MinUI (où se trouve `res/`) :

```bash
/usr/bin/python3 ./minui-ui-preview.py ./res --out ./ui-preview
```

## Résultats

Le dossier `ui-preview/` contient :

| Fichier | Signification |
|---|---|
| `01-root.png` | Menu racine avec des noms de systèmes **d'exemple** |
| `02-games.png` | Dossier Games avec des noms de PAKs **d'exemple** |
| `03-game-boy.png` | Liste de ROMs **d'exemple** |
| `04-brightness.png` | Ajustement de la luminosité en haut de l'écran |
| `05-volume.png` | Ajustement du volume en haut de l'écran |
| `06-no-roms.png` | Image `res/roms.png` **telle quelle** |
| `07-wake.png` | Image `res/wake.png` **telle quelle** |
| `00-res-assets-atlas.png` | **Planche récapitulative** : les vrais PNG du dossier `res/`, avec leurs noms et dimensions |
| `annotated/01-root.png` à `annotated/07-wake.png` | Les mêmes écrans avec **numéros, traits de liaison et noms de fichiers** `res/` sur une colonne extérieure |

Les captures non annotées restent en 320 × 240. Les versions annotées sont agrandies pour que l'on puisse consulter les noms sans masquer le rendu d'origine.

## Fonctionnement des annotations

Chaque repère renvoie à un fichier graphique utilisé pour **l'élément qu'il pointe**. Par exemple :

- Logo : `res/logo.png`.
- Bandeau supérieur : `res/title-bg.png`.
- Fond de sélection : `res/list-selected-bg.png`.
- Batterie dans l'exemple : `res/power-80%-icon.png` (d'autres niveaux existent).
- Bandeau inférieur : `res/tips-bar-bg.png`.
- Bouton rond des touches A/B/X : `res/nav-bar-item-bg.png`.
- Icône MENU : `res/stat-menu-icon.png`.
- Police / textes calculés dans le code : `res/BPreplayBold.otf`.
- Jauge luminosité / volume : `res/settings-bar-empty.png`, `res/settings-bar-full.png`, plus l'icône correspondante.

Les labels des ROMs/PAKs sont des **exemples**, pas un inventaire de la carte SD. La prévisualisation PIL est une **approximation du rendu SDL_ttf**, pas une capture exacte depuis la console. Les menus `libmmenu` n'ont pas été reconstitués : leur code est séparé dans le sous-module `src/libmmenu`.

## Modifier l'interface

Tu peux tester un changement en modifiant **une copie** du fichier PNG dans `res/`, relancer le script, puis comparer la capture correspondante. Ne modifie ni les ressources ni le binaire sur la console avant d'avoir validé la direction voulue.
