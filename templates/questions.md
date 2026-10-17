# Questions d'investigation

Pour chaque réponse : l'heure en **UTC** et une capture où la ligne de preuve est visible.

| N° | Question | Où chercher | Réponse | Capture |
|---|---|---|---|---|
| Q1 | Pourquoi `dir` n'affichait-il pas `$MFT` après l'export ? Quelle commande l'a montré ? | sortie de `attrib` | | |
| Q2 | À quelle heure le dossier `TP_NTFS` a-t-il été créé ? Qu'est-ce qui prouve que c'est un dossier ? | `$UsnJrnl` : `File_Created`, colonne `File Attribute` | | |
| Q3 | Quel est le premier fichier créé dans ce dossier ? Heure et numéro MFT ? | `$UsnJrnl` : `File_Created` | | |
| Q4 | Ce fichier a-t-il été modifié après sa création ? Quelle ligne le montre ? | `$UsnJrnl` : `Data_Added` sans `File_Created` | | |
| Q5 | Quel était l'ancien nom de `rapport_final.txt` ? Comment prouver que c'est le même fichier ? | `File_Renamed_Old` / `File_Renamed_New` + numéro MFT | | |
| Q6 | Quel fichier a été supprimé ? À quelle heure ? Combien de temps a-t-il existé ? | `$UsnJrnl` : `File_Deleted` | | |
| Q7 | Dans FTK Imager, `[root]\TP_NTFS` : quels fichiers voit-on ? Comment `secret.txt` est-il marqué ? | FTK Imager, `File List` | | |
| Q8 | Les heures de `$LogFile` concordent-elles avec celles de `$UsnJrnl` et de `verite_terrain.txt` ? | onglet `$LogFile` | | |
| Bonus | Quel était le contenu de `secret.txt` ? | `$LogFile` + éditeur hexadécimal | | |

## Conclusion (5 lignes)

Ce que chaque journal apporte : ce que `$UsnJrnl` permet de prouver, ce que `$LogFile` ajoute, et pourquoi un fichier « supprimé » laisse quand même des traces.
