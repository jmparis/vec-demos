# vec-demos

Projet de demos Vectrex en assembleur Motorola 6809, avec une toolchain basee sur
LWTOOLS et des cibles d'execution pour emulateurs.

Le code vise la ROM BIOS originale Vectrex et privilegie les routines BIOS
officielles lorsque c'est possible.

## Etat du projet

Le dépot contient actuellement une demo "Hello World" dans `src/hello.asm`.
Cette demo affiche du texte, anime sa position verticale et dessine une forme
vectorielle en rotation via les routines BIOS Vectrex.

L'intégration avec jsvecx est en cours. La cible `run_jsvecx` existe dans le
Makefile, mais cette integration n'est pas encore finalisée.

## Prerequis

- `lwasm` fourni par LWTOOLS
- `make`
- `MAME`, pour `make run_mame`
- `RetroArch` avec le core `VecX`, pour `make run_retroarch`
- `Python 3`, pour servir jsvecx localement avec `make run_jsvecx`

Les chemins vers MAME, RetroArch, le core VecX et jsvecx peuvent etre ajustés
dans le `Makefile` selon l'environnement local.

## Compilation

Afficher les cibles disponibles :

```bash
make
```

Compiler la ROM :

```bash
make all
```

Nettoyer les fichiers generes :

```bash
make clean
```

Le Makefile dérive le nom du programme a partir du nom du dossier : `vec-demos`
devient `demos`, et la source attendue est donc `src/demos.asm`. Si la source
active est `src/hello.asm`, renommer ou dupliquer ce fichier selon la demo a
compiler, ou adapter la variable `SRC` du Makefile.

## Execution

Lancer la ROM avec MAME :

```bash
make run_mame
```

Lancer la ROM avec RetroArch :

```bash
make run_retroarch
```

Lancer la ROM avec jsvecx dans un navigateur :

```bash
make run_jsvecx
```

Cette derniere cible copie la ROM dans `tools/jsvecx/deploy/roms`, affiche une
URL locale, puis lance un serveur HTTP Python sur le port configure par
`JSVECX_PORT`.

## Organisation

- `src/` : sources assembleur 6809 des demos
- `include/` : includes Vectrex, dont les symboles BIOS
- `assets/` : ressources graphiques, vectorielles ou sonores
- `docs/` : documentation technique du projet
- `tools/` : outils externes ou experimentaux, dont jsvecx
- `build/` : fichiers generes par la compilation

## Conventions

- Assembleur compatible LWASM
- Labels en `PascalCase`
- Constantes en `UPPER_CASE`
- Macros en `snake_case`
- Utilisation des symboles BIOS officiels, par exemple `Wait_Recal`,
  `Intensity_a`, `Print_Str_d` ou `Moveto_d`
- Commentaires attendus sur les routines BIOS, les acces hardware, les timings
  critiques et les calculs vectoriels

## Documentation Vectrex

Quelques references utiles :

- Vector Display: https://www.playvectrex.com/designit/chrissalo/vectordisplay.htm
- Appendix A: https://www.playvectrex.com/designit/chrissalo/appendixa.htm
- ROM Reference: https://www.playvectrex.com/designit/chrissalo/appendixa.htm#Reference
- BIOS RAM locations: https://www.playvectrex.com/designit/chrissalo/appendixb.htm
- VIA: https://www.playvectrex.com/designit/chrissalo/via1.htm
- AY-3-8912: https://www.playvectrex.com/designit/chrissalo/psg1.htm
