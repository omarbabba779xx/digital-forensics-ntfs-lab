# Digital Forensics — Forensic du système de fichiers NTFS

> Retrouver, dans les journaux NTFS (`$MFT`, `$UsnJrnl:$J`, `$LogFile`), la trace de six actions simples sur des fichiers : **création, modification, renommage, suppression**.

![Digital Forensics](https://img.shields.io/badge/Digital%20Forensics-NTFS-1b4332?style=for-the-badge)
![Outil](https://img.shields.io/badge/NTFS%20Log%20Tracker-v1.9-2b3a33?style=flat-square)
![Outil](https://img.shields.io/badge/FTK%20Imager-8.3-2b3a33?style=flat-square)
![Statut](https://img.shields.io/badge/statut-r%C3%A9alis%C3%A9%2C%20bonus%20non%20r%C3%A9solu-2b6e44?style=flat-square)

TP de la séance 3 du module *Digital Forensics* (5IIR, EMSI Tanger, 2026/2027). Il fait suite au TP de la séance 2 (acquisition et préservation des preuves) : on réutilise la même méthode (acquérir, vérifier, analyser sur copie) pour répondre à une question plus fine.

> **Aucune preuve brute n'est versionnée.** Images, exports `$MFT` / `$LogFile` / `$J` et bases d'analyse restent hors Git (voir [`.gitignore`](.gitignore)). Ce dépôt contient la méthode, le script de simulation, les réponses, les captures commentées et les empreintes.

---

## Résultat en bref

Les six actions sont retrouvées **à la seconde** dans `$UsnJrnl:$J`, et confirmées dans `$LogFile` (heures UTC, image de l'essai 2).

| Étape | Action | Heure (UTC) | Trace dans `$UsnJrnl` | N° MFT |
|---|---|---|---|---|
| E1 | Créer le dossier `TP_NTFS` | 16:33:07 | `File_Created` (attribut **Directory**) | 32414 |
| E2 | Créer `rapport.txt` | 16:33:46 | `File_Created`, `Data_Added`, `File_Closed` | 32881 |
| E3 | Modifier `rapport.txt` | 16:34:12 | `Data_Added` sans `File_Created` | 32881 |
| E4 | Renommer en `rapport_final.txt` | 16:34:31 | `File_Renamed_Old` / `File_Renamed_New` | 32881 |
| E5 | Créer `secret.txt` | 16:34:47 | `File_Created`, `Data_Added`, `File_Closed` | 29546 |
| E6 | Supprimer `secret.txt` | 16:35:08 | `File_Closed, File_Deleted` | 29546 |

- Le renommage garde le **même numéro MFT** (32881) : c'est la preuve que `rapport_final.txt` est l'ancien `rapport.txt`.
- **Le bonus n'est pas résolu** : le texte de `secret.txt` (« Code d'acces : 4589 ») n'a pu être retrouvé dans aucun des trois essais. Le fait de l'écriture est prouvé, pas le contenu (voir [`rendu/questions.md`](rendu/questions.md)).

### Les trois essais

| | Essai 1 | Essai 2 (référence) | Essai 3 (bonus) |
|---|---|---|---|
| Début de l'acquisition après E6 | 81 min | 9 min 26 s | 10 s |
| Lecture réelle de la zone `$MFT` / `$LogFile` après E6 (estimation) | ≈ 84 min | ≈ 16 min | ≈ 8 min |
| `$LogFile` | **écrasé** (journal circulaire de 64 Mo) | lisible | lisible |
| Entrée MFT de `secret.txt` réattribuée après | + 54 s | + 3 s | + 14 s |
| Texte retrouvé | non | non | non |

Enseignements : un délai de 81 minutes efface `$LogFile` ; une image de disque en marche n'est pas un instantané ; l'entrée MFT d'un fichier supprimé est réattribuée en quelques secondes, ce qui détruit le texte d'un petit fichier.

## État d'avancement

| Étape | État |
|---|---|
| Lecture de l'énoncé, plan de travail | Fait |
| Snapshot `Before_S3_NTFS` (VM éteinte) | Fait, le 17 octobre 2026 à 15:45:08 UTC |
| Simulation des 6 actions dans la VM (3 essais) | Fait |
| Acquisition de l'image `Windows_Victim_S3.E01` et vérification (essai 2) | Fait : MD5 et SHA-1 vérifiés (*Match*), aucun bad block |
| Export de `$MFT`, `$LogFile`, `$UsnJrnl:$J` et contrôle (`attrib`, SHA-1 originaux = copies) | Fait |
| Parsing dans NTFS Log Tracker (UTC) et analyse | Fait |
| Questions Q1 à Q8, chronologie, conclusion | Fait ([`rendu/`](rendu)) |
| Bonus (contenu de `secret.txt`) | Non résolu, documenté |
| Restauration du snapshot `Before_S3_NTFS` | À faire en dernier |

## Pourquoi ce TP

Quand un fichier est supprimé, Windows ne l'efface pas vraiment : NTFS tient plusieurs journaux de ce qui s'est passé. Ils permettent de répondre à une question de base en investigation : **quel fichier a été créé, modifié, renommé ou supprimé, et à quelle heure ?**

Le principe est volontairement simple. On **sait** ce qui a été fait (six actions horodatées par un script) et on doit **retrouver chaque action** dans les journaux. C'est un exercice de calibrage : on apprend à reconnaître la trace de chaque opération avant de devoir l'interpréter sans connaître la vérité terrain.

## Les trois sources NTFS

| Métafichier | Emplacement dans l'image | Question à laquelle il répond | Mémoire |
|---|---|---|---|
| `$MFT` | `[root]\$MFT` | *Quels* fichiers existent ou ont existé, avec leurs dates | État actuel (+ entrées supprimées non réutilisées) |
| `$UsnJrnl:$J` | `[root]\$Extend\$UsnJrnl`, flux `$J` | *Quand* et *comment* un fichier a changé | Jours à semaines |
| `$LogFile` | `[root]\$LogFile` | Quelles opérations bas niveau ont été écrites dans la MFT | Minutes à quelques heures (64 Mo circulaire) |

- Chaque fichier a un **numéro d'entrée MFT**. Il ne change pas quand on renomme le fichier. Une référence de fichier fait 64 bits : 48 bits d'entrée et 16 bits de **séquence**, qui augmente quand l'entrée est réutilisée.
- `$UsnJrnl:$J` est un **flux de données alternatif** (ADS) de `$UsnJrnl`, et un fichier *sparse* (taille logique 584 Mo, environ 38 Mo réellement occupés).
- NTFS stocke les dates en **UTC** : tous les outils sont réglés en UTC. L'horloge de la VM avance d'une heure sur l'UTC.

## La simulation

Le script [`scripts/simulation_S3.ps1`](scripts/simulation_S3.ps1) exécute six actions, séparées de **30 secondes**, et note l'heure UTC de chacune dans `verite_terrain.txt` (écrit sur le support, pas sur le disque de la victime).

| Étape | Action | Commande |
|---|---|---|
| E1 | Créer le dossier `C:\TP_NTFS` | `New-Item -ItemType Directory` |
| E2 | Créer `rapport.txt` | `Set-Content` |
| E3 | Ajouter une ligne | `Add-Content` |
| E4 | Renommer en `rapport_final.txt` | `Rename-Item` |
| E5 | Créer `secret.txt` | `Set-Content` |
| E6 | Supprimer `secret.txt` | `Remove-Item` |

## Méthode

1. **État initial** : snapshot de la VM éteinte (un snapshot « à chaud » écrit la RAM et peut rester bloqué).
2. **Simulation** dans la VM, puis **acquisition** de l'image E01 avec FTK Imager (disque physique, vérification activée).
3. **Export** de `$MFT`, `$LogFile` et du flux `$J`, plus la liste de hash calculée par FTK.
4. **Contrôle** avec `attrib` : ces fichiers sont cachés et système, donc invisibles pour `dir`. Originaux en lecture seule (`attrib +r +s +h`), **copies de travail** pour l'analyse, comparaison des SHA-1.
5. **Parsing** dans NTFS Log Tracker (fuseau UTC, carving désactivé).
6. **Lecture** de l'onglet `$UsnJrnl` (une ligne = un changement), puis recoupement avec `$LogFile`.

Termes à connaître dans la colonne *Event Info* :

| Terme | Signification | Étapes |
|---|---|---|
| `File_Created` | Création du fichier ou du dossier | E1, E2, E5 |
| `Data_Added` | Données écrites (le fichier grossit) | E2, E3, E5 |
| `File_Renamed_Old` / `File_Renamed_New` | Ancien nom / nouveau nom | E4 |
| `File_Deleted` | Suppression | E6 |
| `File_Closed` | Le programme a fermé le fichier : fin de l'opération | toutes |

## Captures

Les captures annotées (cadres rouges numérotés) sont dans [`docs/screenshots`](docs/screenshots), numérotées dans l'ordre du TP : simulation, acquisition et vérification, export, contrôle des attributs et des hash, parsing, lecture de `$UsnJrnl` et de `$LogFile`, vue de FTK Imager, puis l'essai 3 du bonus. Le nom d'utilisateur de la VM y est flouté.

**Pour tout suivre dans l'ordre, étape par étape, avec chaque capture expliquée : [`docs/deroule-pas-a-pas.md`](docs/deroule-pas-a-pas.md).**

## Structure du dépôt

```
.
├── README.md
├── .gitignore                  exclut images, exports, bases d'analyse et binaires
├── scripts/
│   └── simulation_S3.ps1       les 6 actions horodatées en UTC
├── rendu/
│   ├── chronologie.md          tableau de chronologie et recoupement des trois sources
│   └── questions.md            réponses Q1 à Q8, bonus, conclusion
└── docs/
    ├── deroule-pas-a-pas.md    le TP dans l'ordre chronologique, chaque capture expliquée
    └── screenshots/            captures annotées
```

## Avertissement

Usage pédagogique, sur machines de laboratoire uniquement. Le script de simulation doit être exécuté **uniquement** dans la VM de laboratoire.
