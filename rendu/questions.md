# Questions d'investigation (réponses)

Toutes les heures sont en **UTC**. Image de référence : **essai 2**. Les captures sont dans [`docs/screenshots`](../docs/screenshots).

| N° | Question | Réponse | Capture |
|---|---|---|---|
| Q1 | Pourquoi `dir` n'affichait-il pas `$MFT` après l'export ? Quelle commande l'a montré ? | Parce que `$MFT`, `$LogFile` et `$J` portent les attributs **Système (S)** et **Caché (H)**, et que `dir` masque ces fichiers par défaut. `dir /a` les affiche, et `attrib` montre explicitement `S H`. | [07](../docs/screenshots/07_dir_dir-a_attrib.png) |
| Q2 | À quelle heure `TP_NTFS` a-t-il été créé ? Qu'est-ce qui prouve que c'est un dossier ? | **16:33:07**. La colonne *File Attribute* vaut **Directory** (USN 583962120, `File_Created`) ; pour un fichier ce serait *Archive*. | [11](../docs/screenshots/11_usnjrnl_dossier_tp_ntfs_e1.png) |
| Q3 | Premier fichier créé dans ce dossier ? Heure et numéro MFT ? | `rapport.txt`, créé à **16:33:46** (USN 584003888), **MFT 32881**, dossier parent 32414. | [12](../docs/screenshots/12_usnjrnl_rapport_e2_e3_e4.png) |
| Q4 | Ce fichier a-t-il été modifié après sa création ? Quelle ligne le montre ? | **Oui**, à **16:34:12** : `Data_Added` (USN 584128136) puis `Data_Added, File_Closed`, **sans** `File_Created`. `$LogFile` le confirme (*Updating Modified Time*). Taille finale 61 octets = 30 + 31. | [12](../docs/screenshots/12_usnjrnl_rapport_e2_e3_e4.png), [14](../docs/screenshots/14_logfile_rapport_e2_e3.png) |
| Q5 | Ancien nom de `rapport_final.txt` ? Comment prouver que c'est le même fichier ? | `rapport.txt` (`File_Renamed_Old`, 16:34:31, USN 584140048). Preuve : le **même numéro MFT 32881** avant et après (même *FileReferenceNumber* `0x0002000000008071`). | [12](../docs/screenshots/12_usnjrnl_rapport_e2_e3_e4.png), [15](../docs/screenshots/15_logfile_renommage_e4.png) |
| Q6 | Quel fichier a été supprimé ? À quelle heure ? Combien de temps a-t-il existé ? | `secret.txt` (MFT 29546), supprimé à **16:35:08** (`File_Deleted`, USN 584155608). Créé à 16:34:47 : il a existé **21 secondes**. | [13](../docs/screenshots/13_usnjrnl_secret_e5_e6.png), [16](../docs/screenshots/16_logfile_secret_e5_e6.png) |
| Q7 | Dans FTK Imager, `[root]\TP_NTFS` : quels fichiers voit-on ? Comment `secret.txt` est-il marqué ? | On ne voit que `rapport_final.txt` (61 octets). **`secret.txt` n'apparaît pas**, même comme fichier supprimé : son entrée MFT 29546 a été réattribuée (séquence 44 à la création, 53 aujourd'hui). | [17](../docs/screenshots/17_ftk_dossier_tp_ntfs_q7.png) |
| Q8 | Les heures de `$LogFile` concordent-elles avec `$UsnJrnl` et `verite_terrain.txt` ? | **Oui**, à la seconde (E1 à E5) ; E6 est ordonnée par LSN dans `$LogFile` et vaut 16:35:08 dans les deux autres sources. | [14](../docs/screenshots/14_logfile_rapport_e2_e3.png), [15](../docs/screenshots/15_logfile_renommage_e4.png), [16](../docs/screenshots/16_logfile_secret_e5_e6.png) |
| Bonus | Quel était le contenu de `secret.txt` ? | **Non retrouvé** (essais 2 et 3). Voir ci-dessous. | [16](../docs/screenshots/16_logfile_secret_e5_e6.png) |

## Le bonus : le texte n'a pas pu être retrouvé

Le fait d'écrire 21 octets dans `secret.txt` puis de le supprimer est **prouvé** (noms, heures, tailles, numéro MFT). Le **contenu** (« Code d'acces : 4589 ») ne l'est pas, après trois essais :

| | Essai 1 | Essai 2 | Essai 3 |
|---|---|---|---|
| Début de l'acquisition après E6 | 81 min | 9 min 26 s | 10 s |
| Lecture réelle de la zone `$MFT` / `$LogFile` après E6 (estimation) | ≈ 84 min | ≈ 16 min | ≈ 8 min |
| `$UsnJrnl` | 6 actions | 6 actions | 6 actions |
| `$LogFile` | écrasé | lisible, sans le texte | lisible, sans le texte |
| Entrée MFT de `secret.txt` réattribuée après la suppression | + 54 s | + 3 s | + 14 s |
| Texte retrouvé | non | non (balayage de toute l'image) | non |

- L'image n'est **pas un instantané** : FTK lit le disque pendant 1 à 2 heures. Le délai qui compte est le moment où la zone `$MFT` / `$LogFile` est lue, pas le début de la copie.
- L'entrée MFT d'un fichier de 21 octets contient son texte (fichier « résident »). Elle est réattribuée à un fichier temporaire de Windows en quelques secondes : le texte est écrasé avant toute acquisition possible.
- Dans `$LogFile`, l'enregistrement de l'écriture de `secret.txt` (LSN 2652231662) déclare 21 octets mais ne contient pas ces octets (même constat pour `rapport.txt`, 30 octets). Je constate ce comportement sans l'expliquer.

Je ne conclus pas au-delà de ce qui est démontré : sur cette VM (Windows 10, build 19045) le texte n'est pas lisible ; je n'ai pas testé d'autres versions de Windows.

## Conclusion

`$UsnJrnl` permet de prouver **quoi et quand** : une ligne horodatée par changement, de la création au renommage et à la suppression, avec le chemin reconstruit. `$LogFile` ajoute le **comment** : opérations de bas niveau sur la MFT, ancien et nouveau nom d'un renommage, taille des données écrites. Le numéro MFT, qui ne change pas au renommage, relie les lignes d'un même fichier, et deux journaux concordants à la seconde forment une preuve solide. Un fichier « supprimé » laisse des traces parce que NTFS ne l'efface pas : il libère l'entrée MFT et note l'événement dans ses journaux, jusqu'à ce que l'entrée soit réutilisée et que le journal circulaire soit réécrit. D'où la règle pratique : acquérir vite, tout en sachant que le **contenu** d'un petit fichier supprimé disparaît presque aussitôt.
