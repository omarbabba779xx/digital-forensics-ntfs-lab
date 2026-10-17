# simulation_S3.ps1 - A executer UNIQUEMENT dans la VM de labo
# Support de collecte : E: (lecteur du dossier partage). Executer dans un PowerShell NON administrateur.
$support = "E:"
$dossier = "C:\TP_NTFS"
$journal = "$support\Evidence\S3\verite_terrain.txt"   # sur le support, pas sur C:
New-Item -ItemType Directory -Force -Path "$support\Evidence\S3" | Out-Null

function Note($etape, $texte) {
    $heure = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    "$heure UTC | $etape | $texte" | Tee-Object -FilePath $journal -Append
    Start-Sleep -Seconds 30
}

# E1 - Creer un dossier
New-Item -ItemType Directory -Path $dossier | Out-Null
Note "E1" "Creation du dossier C:\TP_NTFS"

# E2 - Creer un fichier
Set-Content -Path "$dossier\rapport.txt" -Value "Rapport de stage - version 1"
Note "E2" "Creation de rapport.txt"

# E3 - Modifier le fichier
Add-Content -Path "$dossier\rapport.txt" -Value "Ajout : conclusion du rapport"
Note "E3" "Modification de rapport.txt"

# E4 - Renommer le fichier
Rename-Item -Path "$dossier\rapport.txt" -NewName "rapport_final.txt"
Note "E4" "Renommage rapport.txt -> rapport_final.txt"

# E5 - Creer un second fichier
Set-Content -Path "$dossier\secret.txt" -Value "Code d'acces : 4589"
Note "E5" "Creation de secret.txt"

# E6 - Supprimer ce fichier (suppression definitive, sans Corbeille)
Remove-Item -Path "$dossier\secret.txt"
Note "E6" "Suppression de secret.txt"
Write-Host "Termine : lancer l'acquisition tout de suite."