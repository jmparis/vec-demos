# Starfield

Ce dossier contient un effet de champ d'étoiles Vectrex en assembleur 6809.
Le fichier principal est `starfield.asm`. Le fichier `macro.i` fournit une
partie importante des macros bas niveau utilisees par cet effet.

## Vue d'ensemble

`starfield.asm` gere des etoiles sous forme d'objets stockes dans des listes
chainees. Le code ne cree pas d'objet dynamiquement comme le ferait un langage
haut niveau: il prend un objet dans une liste d'objets libres, l'initialise,
puis le place dans la liste des objets actifs.

Deux têtes de liste sont utilisees:

- `starlist_empty_head`: premier objet libre disponible.
- `starlist_objects_head`: premier objet actif a animer et afficher.

Chaque objet contient au minimum:

- `NEXT_STAR_OBJECT`: pointeur vers l'objet suivant.
- `BEHAVIOUR`: adresse de la routine de comportement de l'objet.
- `Y1_POS` a `Y4_POS`: positions verticales des quatre etoiles de l'objet.
- `X1_POS` a `X4_POS`: positions horizontales des quatre etoiles de l'objet.
- `TWINKLE`: valeur de scintillement/intensite.

Les offsets de ces champs sont maintenant definis au debut de `starfield.asm`,
avec la zone RAM reservee au moteur starfield.

## Allocation d'un objet

La routine `newStarObject` prend le premier objet disponible dans
`starlist_empty_head`.

Elle verifie d'abord que l'adresse chargee dans `U` est utilisable:

```asm
        ldu     starlist_empty_head
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        bls     cs_done_star
```

Si aucun objet libre n'est disponible, la routine sort directement.
Sinon, elle retire l'objet de la liste libre et l'insere en tete de la liste
des objets actifs:

```asm
        ldd     NEXT_STAR_OBJECT,u
        std     starlist_empty_head

        ldd     starlist_objects_head
        std     NEXT_STAR_OBJECT,u

        stu     starlist_objects_head
        inc     starCount
```

En sortie, `U` pointe sur le nouvel objet actif.

## Initialisation d'une etoile

La routine `spawnStar` appelle `newStarObject`, puis initialise l'objet obtenu.

Le nouvel objet est copie dans `X`:

```asm
        leax    ,u
```

Sa routine de comportement est installee dans le champ `BEHAVIOUR`:

```asm
        ldd     #simpleStarBehaviour2
        std     BEHAVIOUR,x
```

Dans l'etat actuel du code, c'est donc `simpleStarBehaviour2` qui est utilisee
pour les nouveaux objets. `simpleStarBehaviour` reste presente dans le fichier,
mais elle n'est pas referencee par `spawnStar`.

Les positions `Y1` a `Y4` et `X1` a `X4` sont ensuite remplies avec la macro
`RANDOM_A`, qui charge une valeur pseudo-aleatoire dans le registre `A`.

`TWINKLE` est aussi initialise avec une valeur pseudo-aleatoire, mais bornee:

```asm
        RANDOM_A
        anda    #%01111111
        ora     #8
        sta     TWINKLE , x
```

Le masque garde les 7 bits bas, puis `ora #8` force une intensite minimale.

## Constantes de scintillement

Le fichier definit:

```asm
STAR_SHIFT          =        %01100000
STAR_SHIFT          =        %00011110
TWINKLE_AND         =        %00111111
TWINKLE_OR          =        %00001111
```

`TWINKLE_AND` et `TWINKLE_OR` servent a limiter puis relever la valeur
d'intensite:

```asm
        anda    #TWINKLE_AND
        ora     #TWINKLE_OR
```

Attention: `STAR_SHIFT` est defini deux fois. Selon le comportement de LWASM,
la seconde definition peut remplacer la premiere ou produire un diagnostic.
La valeur effectivement voulue meriterait d'etre clarifiee.

## Macros Vectrex utilisees

Plusieurs macros appelees par `starfield.asm` sont fournies par `macro.i`.

### `RANDOM_A`

`RANDOM_A` implemente un generateur pseudo-aleatoire de type LFSR base sur
`random_seed`. Elle charge la nouvelle valeur dans `A` et la stocke dans
`random_seed`.

### `MY_MOVE_TO_D_START`

Cette macro demarre un deplacement du faisceau vers une position donnee dans
`D`, avec `A` pour `Y` et `B` pour `X`.

Elle manipule directement le VIA:

- `VIA_port_a` pour charger les valeurs D/A.
- `VIA_cntl` pour controler le blanking et le zero.
- `VIA_port_b` pour le multiplexeur.
- `VIA_t1_cnt_hi` pour lancer le timer de deplacement.

### `MY_MOVE_TO_B_END`

Cette macro attend la fin du deplacement en testant le flag du timer VIA:

```asm
        LDB     #$40
LF33D?: BITB    <VIA_int_flags
        BEQ     LF33D?
```

Elle est utilisee apres `MY_MOVE_TO_D_START` pour attendre que le faisceau ait
termine son mouvement avant de tracer.

### `_INTENSITY_A`

`_INTENSITY_A` configure l'intensite du faisceau avec la valeur contenue dans
`A`. Elle ecrit dans le D/A via le VIA, puis selectionne le canal d'intensite
avec `VIA_port_b`.

### `_ZERO_VECTOR_BEAM2`

`_ZERO_VECTOR_BEAM2` est definie localement dans `starfield.asm`, pas dans
`macro.i`.

Elle est proche de `_ZERO_VECTOR_BEAM`, mais elle ecrit aussi dans
`VIA_shift_reg`:

```asm
_ZERO_VECTOR_BEAM2 macro
        sta     <VIA_shift_reg
        LDB     #$CC
        STB     VIA_cntl
        endm
```

Elle sert a declencher le trace court de l'etoile en controlant le blanking,
le zero et le registre de decalage du VIA.

## `simpleStarBehaviour`

`simpleStarBehaviour` est une premiere routine de comportement pour un objet
contenant quatre etoiles.

Pour chaque etoile, la routine suit le schema suivant:

1. Aller a la position courante.
2. Modifier la coordonnee verticale.
3. Si l'etoile depasse la limite, tirer une nouvelle position aleatoire.
4. Mettre a jour `TWINKLE`.
5. Regler l'intensite.
6. Tracer un petit vecteur ou point lumineux.

Pour la premiere etoile:

```asm
        MY_MOVE_TO_D_START
        dec     Y1_POS+u_offset1,s
        bvc     notBottom1
        RANDOM_A
        sta     X1_POS+u_offset1,s
```

Le `dec` fait evoluer la position verticale. Le test `bvc` utilise le flag
overflow pour detecter le passage de limite. Quand la limite est franchie,
une nouvelle position horizontale est choisie.

La fin de la routine prepare l'objet suivant:

```asm
        lds     NEXT_STAR_OBJECT+u_offset1,s
        puls    d,pc
```

Ce code suppose que `S` sert de pointeur vers l'objet courant. Charger
`NEXT_STAR_OBJECT` dans `S`, puis faire `puls d,pc`, permet de chainer
rapidement vers l'objet suivant dans le moteur d'objets.

## `removeOneStar`

`removeOneStar` retire un objet actif et le remet dans la liste des objets
libres.

Dans l'etat actuel du code, la routine retire toujours la tete de
`starlist_objects_head`:

```asm
        ldx     starlist_objects_head
        ldu     NEXT_STAR_OBJECT,x
        stu     starlist_objects_head
```

Puis elle remet l'objet dans la liste libre:

```asm
        ldy     starlist_empty_head
        sty     NEXT_STAR_OBJECT,x
        stx     starlist_empty_head
```

Le bloc `was_not_first_star` semble prevu pour supprimer un objet qui ne serait
pas en tete de liste, mais il est actuellement inaccessible a cause du
branchement direct vers `starCleanupDone`.

## `simpleStarBehaviour2`

`simpleStarBehaviour2` est la routine effectivement installee par `spawnStar`.
Elle produit un effet de scintillement avec repositionnement aleatoire quand
la valeur `TWINKLE` atteint une limite.

La routine commence par charger `TWINKLE` dans le timer 1 du VIA:

```asm
        lda     TWINKLE +u_offset1,s
        sta     <VIA_t1_cnt_lo
```

Puis elle demarre le deplacement vers la premiere etoile:

```asm
        lda     Y1_POS+u_offset1,s
        MY_MOVE_TO_D_START
```

Ensuite, `TWINKLE` augmente progressivement:

```asm
        lda     TWINKLE +u_offset1,s
        lsra
        lsra
        lsra
        lsra
        bne     addyeah
        lda     #1
addyeah
        adda    TWINKLE +u_offset1,s
        sta     TWINKLE +u_offset1,s
```

Cela revient a ajouter environ `TWINKLE / 16` a la valeur courante, avec un
minimum de `+1`.

Quand `TWINKLE` atteint `$7f`, la routine le remet a `8` et reinitialise les
positions des quatre etoiles avec `RANDOM_A`:

```asm
        cmpa    #$7f
        blo     constar2
        lda     #8
        sta     TWINKLE +u_offset1,s
```

La section `constar2` trace ensuite les quatre etoiles aux positions courantes.

## Points a verifier

- `STAR_SHIFT` est defini deux fois.
- `simpleStarBehaviour` est conservee mais n'est pas utilisee par `spawnStar`.
- `removeOneStar` contient un chemin de suppression non tete qui est
  actuellement inaccessible.
- `macro.i` fournit les macros bas niveau, mais il depend aussi de symboles
  comme `random_seed`, `VIA_*` et des variables BIOS ou RAM du projet.
