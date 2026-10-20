# Tableau de chronologie

Une heure par action, en **UTC**, retrouvée dans l'onglet `$UsnJrnl:$J` de NTFS Log Tracker. Image de référence : **essai 2** (simulation de 16:33 à 16:35 UTC le 18/10/2026).

| Étape | Action effectuée | Heure retrouvée (UTC) | Event Info observé | N° MFT |
|---|---|---|---|---|
| E1 | Création du dossier `TP_NTFS` | 16:33:07 | `File_Created`, puis `File_Created, File_Closed` ; *File Attribute* = **Directory** | 32414 |
| E2 | Création de `rapport.txt` | 16:33:46 | `File_Created`, `Data_Added`, `File_Closed` | 32881 |
| E3 | Modification de `rapport.txt` | 16:34:12 | `Data_Added`, puis `Data_Added, File_Closed` (sans `File_Created`) | 32881 |
| E4 | Renommage en `rapport_final.txt` | 16:34:31 | `File_Renamed_Old` (`rapport.txt`), `File_Renamed_New` (`rapport_final.txt`) | 32881 |
| E5 | Création de `secret.txt` | 16:34:47 | `File_Created`, `Data_Added`, `File_Closed` | 29546 |
| E6 | Suppression de `secret.txt` | 16:35:08 | `File_Closed, File_Deleted` | 29546 |

Captures : [`11`](../docs/screenshots/11_usnjrnl_dossier_tp_ntfs_e1.png), [`12`](../docs/screenshots/12_usnjrnl_rapport_e2_e3_e4.png) et [`13`](../docs/screenshots/13_usnjrnl_secret_e5_e6.png).

## Recoupement avec `verite_terrain.txt` et `$LogFile`

| Étape | Heure notée par le script | Heure retrouvée dans `$UsnJrnl` | Écart (s) | Heure dans `$LogFile` |
|---|---|---|---|---|
| E1 | 16:33:07 | 16:33:07 | 0 | 16:33:07 (Directory Creation) |
| E2 | 16:33:46 | 16:33:46 | 0 | 16:33:46 (File Creation, Writing Size 30) |
| E3 | 16:34:12 | 16:34:12 | 0 | 16:34:12 (Updating Modified Time, indiquée dans *Detail*) |
| E4 | 16:34:31 | 16:34:31 | 0 | 16:34:31 (Renaming File `rapport.txt -> rapport_final.txt`) |
| E5 | 16:34:47 | 16:34:47 | 0 | 16:34:47 (File Creation, Writing Size 21) |
| E6 | 16:35:08 | 16:35:08 | 0 | pas d'heure propre : File Deletion placée par son LSN (2652264855), après l'écriture d'E5 |

Les trois sources concordent à la seconde. Dans `$LogFile`, l'outil n'affiche l'heure que sur certaines lignes ; les autres sont ordonnées par leur numéro de LSN.

Captures : [`14`](../docs/screenshots/14_logfile_rapport_e2_e3.png), [`15`](../docs/screenshots/15_logfile_renommage_e4.png) et [`16`](../docs/screenshots/16_logfile_secret_e5_e6.png).
