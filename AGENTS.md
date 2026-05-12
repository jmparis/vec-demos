# AGENTS.md

## Projet

Développement Vectrex en assembleur Motorola 6809.

Toolchain principale :
- lwasm
- lwlink
- MAME / RetroArch avec CORE VecX / vide pour l'émulation

Le code cible la ROM BIOS originale Vectrex.

---

## Documentation importante

### ROM BIOS Vectrex

Documentation officielle :
- https://www.playvectrex.com/designit/chrissalo/vectordisplay.htm
- https://www.playvectrex.com/designit/chrissalo/appendixa.htm#Reference
- https://www.playvectrex.com/designit/chrissalo/appendixb.htm
- https://www.playvectrex.com/designit/chrissalo/via1.htm
- https://www.playvectrex.com/designit/chrissalo/via2.htm
- https://www.playvectrex.com/designit/chrissalo/via3.htm
- https://www.playvectrex.com/designit/chrissalo/psg1.htm
- https://www.playvectrex.com/designit/chrissalo/psg2.htm
- https://www.playvectrex.com/designit/chrissalo/appendixf.htm


Références BIOS :
- routines système
- table des vecteurs
- variables RAM système
- timings

IMPORTANT :
Toujours utiliser les symboles BIOS officiels lorsque possible.

Exemples :
- Wait_Recal
- Intensity_a
- Print_Str_d
- Moveto_d

---

## Conventions Assembleur

- Syntaxe compatible LWASM
- Labels en PascalCase
- Constantes en UPPER_CASE
- Commentaires obligatoires sur :
  - accès hardware
  - timings
  - routines BIOS
  - calculs vectoriels

Toujours préférer :
```asm
JSR Wait_Recal
```
à des adresses hardcodées :
```asm
JSR $F192
```

---

## Organisation du projet
- assets/
sprites, vecteurs, musiques
- build/
fichiers générés
- docs/
documentation technique
- include/
fichiers .inc Vectrex
- src/
Code assembleur principal


## Compilation

Le projet utilise un **Makefile**.

Commandes disponibles :

1. Compilation complète
```bash
make all
```

Compile toutes les sources et génère la ROM.

2. Nettoyage
```bash
make clean
```

Supprime tous les fichiers générés.

3. Exécution de la ROM sur MAME
```bash
make run_mame
```
Lance la ROM dans MAME.

4. Exécution de la ROM dans RetroArch
```bash
make run_retroarch
```
Lance la ROM dans RetroArch.

La compilation peut-être complétée, si necessaire par

Compilation :
```bash
lwasm -f raw -o build/game.bin src/main.asm
```

Lien :
```bash
lwlink -b vectrex -o build/game.vec build/game.bin
```


## Conventions Assembleur
### Syntaxe
- Syntaxe compatible LWASM
- Code compatible assembleur Motorola 6809

### Labels
- Labels : PascalCase
- Constantes : UPPER_CASE
- Macros : snake_case

### Commentaires

Les commentaires sont obligatoires pour :
- accès hardware
- routines BIOS
- timings critiques
- calculs vectoriels
- optimisations non triviales


## Style de code attendu

### Le code généré doit :
- lisible
- maintenable
- être compact
- être commenté
- éviter les optimisations obscures
- rester compatible Vectrex réelle
- compatible hardware réel

### Le code doit éviter :
- les magic numbers
- les adresses BIOS hardcodées
- les optimisations obscures sans commentaire


## Bonnes pratiques

Avant de proposer du code :
- Vérifier si une routine BIOS existe déjà
- Réutiliser les includes existants
- Respecter les conventions du projet
- Ajouter des commentaires utiles
- Vérifier la compatibilité LWASM


## Contraintes importantes
- Éviter les magic numbers BIOS
- Respecter les timings Vectrex
- Optimiser la taille ROM
- Préférer les macros réutilisables
- Éviter les écritures directes PSG sans commentaire


## Instructions spécifiques pour Codex

Lors de la génération de code :
- privilégier les routines BIOS Vectrex
- éviter les accès mémoire arbitraires
- conserver une compatibilité Vectrex réelle
- générer du code assembleur 6809 valide LWASM
- produire des exemples directement compilables

Lors de la modification de code existant :
- préserver le style du projet
- éviter les changements inutiles
- ne pas casser les labels publics
- conserver les commentaires existants


---