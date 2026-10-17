# Digital Forensics — Forensic du système de fichiers NTFS

> Retrouver, dans les journaux NTFS (`$MFT`, `$UsnJrnl:$J`, `$LogFile`), la trace de six actions simples sur des fichiers : **création, modification, renommage, suppression**.

![Digital Forensics](https://img.shields.io/badge/Digital%20Forensics-NTFS-1b4332?style=for-the-badge)
![Outil](https://img.shields.io/badge/NTFS%20Log%20Tracker-v1.9-2b3a33?style=flat-square)
![Outil](https://img.shields.io/badge/FTK%20Imager-8.3-2b3a33?style=flat-square)
![Statut](https://img.shields.io/badge/statut-en%20cours-b86e00?style=flat-square)

TP de la séance 3 du module *Digital Forensics* (4IIR, EMSI Tanger, 2026/2027). Il fait suite au TP de la séance 2 (acquisition et préservation des preuves) : on réutilise la même méthode (acquérir, vérifier, analyser sur copie) pour répondre à une question plus fine.

> **Aucune preuve brute n'est versionnée.** Images, exports `$MFT` / `$LogFile` / `$J` et bases d'analyse restent hors Git (voir [`.gitignore`](.gitignore)). Ce dépôt contient la méthode, le script de simulation, les modèles de rendu et, au fil de l'avancement, les captures commentées et les empreintes.

---

## État d'avancement

| Étape | État |
|---|---|
| Lecture de l'énoncé, plan de travail | Fait |
| Retour à un état initial de la VM (restauration du snapshot du TP précédent) | Fait |
| Snapshot `Before_S3_NTFS` (VM éteinte) | Fait, le 17 octobre 2026 à 15:45:08 UTC |
| Support préparé (arborescence `Evidence\S3\`, script de simulation) | Fait |
| Simulation des 6 actions dans la VM | À faire |
| Acquisition de l'image `Windows_Victim_S3.E01` et vérification | À faire |
| Export de `$MFT`, `$LogFile`, `$UsnJrnl:$J` et contrôle (`attrib`, hash) | À faire |
| Parsing dans NTFS Log Tracker et analyse | À faire |
| Questions Q1 à Q8, chronologie, conclusion | À faire |

Ce tableau est mis à jour à chaque étape terminée.

## Pourquoi ce TP

Quand un fichier est supprimé, Windows ne l'efface pas vraiment : NTFS tient plusieurs journaux de ce qui s'est passé. Ils permettent de répondre à une question de base en investigation : **quel fichier a été créé, modifié, renommé ou supprimé, et à quelle heure ?**

Le principe est volontairement simple. On **sait** ce qui a été fait (six actions horodatées par un script) et on doit **retrouver chaque action** dans les journaux. C'est un exercice de calibrage : on apprend à reconnaître la trace de chaque opération avant de devoir l'interpréter sans connaître la vérité terrain.

## Les trois sources NTFS

| Métafichier | Emplacement dans l'image | Question à laquelle il répond | Mémoire |
|---|---|---|---|
| `$MFT` | `[root]\$MFT` | *Quels* fichiers existent ou ont existé, avec leurs dates | État actuel (+ entrées supprimées non réutilisées) |
| `$UsnJrnl:$J` | `[root]\$Extend\$UsnJrnl`, flux `$J` | *Quand* et *comment* un fichier a changé | Jours à semaines |
| `$LogFile` | `[root]\$LogFile` | Quelles opérations bas niveau ont été écrites dans la MFT | Minutes à quelques heures (64 Mo circulaire) |

- Chaque fichier a un **numéro d'entrée MFT**. Il ne change pas quand on renomme le fichier : c'est lui qui prouve que `rapport_final.txt` *est* l'ancien `rapport.txt`.
- `$UsnJrnl:$J` est un **flux de données alternatif** (ADS) de `$UsnJrnl`.
- NTFS stocke les dates en **UTC** : tous les outils sont réglés en UTC.

## La simulation

Le script [`scripts/simulation_S3.ps1`](scripts/simulation_S3.ps1) exécute six actions, séparées de **30 secondes** pour qu'on les distingue dans les journaux, et note l'heure UTC de chacune dans `verite_terrain.txt` (écrit sur le support, pas sur le disque de la victime).

| Étape | Action | Commande | Trace attendue |
|---|---|---|---|
| E1 | Créer le dossier `C:\TP_NTFS` | `New-Item -ItemType Directory` | Création d'un **dossier** |
| E2 | Créer `rapport.txt` | `Set-Content` | Création d'un **fichier** |
| E3 | Ajouter une ligne | `Add-Content` | Une **modification** |
| E4 | Renommer en `rapport_final.txt` | `Rename-Item` | Un **renommage** |
| E5 | Créer `secret.txt` | `Set-Content` | Création d'un fichier |
| E6 | Supprimer `secret.txt` | `Remove-Item` | Une **suppression** |

> Il faut acquérir l'image **tout de suite après** : `$LogFile` est un journal circulaire de 64 Mo, réécrit en quelques dizaines de minutes sur un système actif.

## Méthode

1. **État initial** : snapshot de la VM, VM éteinte (un snapshot « à chaud » écrit la RAM et peut rester bloqué).
2. **Simulation** dans la VM, puis **acquisition** de l'image E01 avec FTK Imager (disque physique, vérification activée).
3. **Ouverture de l'image** sur la machine d'analyse, vérification d'intégrité, partition NTFS principale.
4. **Export** de `$MFT`, `$LogFile` et du flux `$J`, plus la liste de hash calculée par FTK.
5. **Contrôle** avec `attrib` : ces fichiers sont cachés et système, donc invisibles pour `dir`. Originaux en lecture seule, **copies de travail** pour l'analyse, comparaison des SHA-1.
6. **Parsing** dans NTFS Log Tracker (fuseau UTC, carving désactivé).
7. **Lecture** de l'onglet `$UsnJrnl` (une ligne = un changement), puis recoupement avec `$LogFile`.

Six termes à connaître dans la colonne *Event Info* :

| Terme | Signification | Étapes |
|---|---|---|
| `File_Created` | Création du fichier ou du dossier | E1, E2, E5 |
| `Data_Added` | Données écrites (le fichier grossit) | E2, E3, E5 |
| `File_Renamed_Old` | Ancien nom, juste avant un renommage | E4 |
| `File_Renamed_New` | Nouveau nom, juste après | E4 |
| `File_Deleted` | Suppression | E6 |
| `File_Closed` | Le programme a fermé le fichier : fin de l'opération | toutes |

## Critères de réussite

- **Intégrité** : image vérifiée, originaux en lecture seule, analyse sur des copies, hash identiques.
- **Méthode** : toutes les heures en UTC, chaque réponse appuyée par une capture.
- **Compréhension** : le fichier renommé est suivi par son **numéro MFT**, pas seulement par son nom.

## Rendu

Les modèles à compléter sont dans [`templates/`](templates) : [`chronologie.md`](templates/chronologie.md) (tableau de chronologie et recoupement) et [`questions.md`](templates/questions.md) (Q1 à Q8, bonus, conclusion).

## Structure du dépôt

```
.
├── README.md
├── .gitignore                  exclut images, exports, bases d'analyse et binaires
├── scripts/
│   └── simulation_S3.ps1       les 6 actions horodatées en UTC
├── templates/
│   ├── chronologie.md          tableau de chronologie à compléter
│   └── questions.md            questions d'investigation Q1 à Q8
└── docs/
    └── screenshots/            captures commentées (ajoutées au fil du TP)
```

## Avertissement

Usage pédagogique, sur machines de laboratoire uniquement. Le script de simulation doit être exécuté **uniquement** dans la VM de laboratoire.
