# Maintient automatiquement le tunnel USB "adb reverse tcp:8000 tcp:8000"
# tant qu'un appareil Android physique est branché, quel que soit le Wi-Fi
# du PC (voir CLAUDE.md D.4 : le device physique contacte alors le serveur
# via 127.0.0.1, jamais via l'IP Wi-Fi).
#
# Tourne en tâche de fond en continu (lancé au démarrage de Windows via le
# raccourci du dossier Démarrage). Ne fait rien de visible, aucune action
# manuelle requise même après avoir débranché/rebranché le téléphone ou
# changé de réseau Wi-Fi.

$adb = "C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe"

while ($true) {
    if (Test-Path $adb) {
        $devices = & $adb devices 2>$null
        if ($devices -match "\tdevice$") {
            & $adb reverse tcp:8000 tcp:8000 2>$null | Out-Null
        }
    }
    Start-Sleep -Seconds 3
}
