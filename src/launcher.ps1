Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$installDir = "$HOME\AppData\Local\.minecraft_launcher"
$javaDir = "$installDir\runtime\java\jdk-21.0.2+13-jre"
$mcDir = "$installDir"
$versionsDir = "$mcDir\versions"
$librariesDir = "$mcDir\libraries"
$assetsDir = "$mcDir\assets"
$assetsIndexesDir = "$assetsDir\indexes"
$assetsObjectsDir = "$assetsDir\objects"
$nativesDir = "$versionsDir\natives"
$userDataFile = "$installDir\userdata.json"

$dirsToCreate = @($installDir, $javaDir, $mcDir, $versionsDir, $librariesDir, $assetsDir, $assetsIndexesDir, $assetsObjectsDir, $nativesDir)
foreach ($dir in $dirsToCreate) {
    if (-Not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Set-ItemProperty -Path $installDir -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

function Download-File {
    param (
        [string]$Url,
        [string]$Output
    )
    if (-Not (Test-Path $Output)) {
        $filename = Split-Path $Output -Leaf
        $client = New-Object System.Net.WebClient
        $form.statusLabel.Text = "Downloading: $filename"
        $client.DownloadFile($Url, $Output)
    }
}

function Get-SavedUsername {
    if (Test-Path $userDataFile) {
        $userData = Get-Content $userDataFile | ConvertFrom-Json
        return $userData.username
    }
    return $null
}

function Save-Username {
    param([string]$username)
    $userData = @{ username = $username }
    $userData | ConvertTo-Json | Set-Content $userDataFile
}

function Show-LoadingPopup {
    param([string]$Message)
    
    $loadingForm = New-Object System.Windows.Forms.Form
    $loadingForm.Text = "Loading"
    $loadingForm.Size = New-Object System.Drawing.Size(300, 150)
    $loadingForm.StartPosition = "CenterScreen"
    $loadingForm.FormBorderStyle = "FixedDialog"
    $loadingForm.ControlBox = $false
    $loadingForm.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

    $loadingLabel = New-Object System.Windows.Forms.Label
    $loadingLabel.Location = New-Object System.Drawing.Point(20, 20)
    $loadingLabel.Size = New-Object System.Drawing.Size(260, 40)
    $loadingLabel.Text = $Message
    $loadingLabel.ForeColor = [System.Drawing.Color]::White
    $loadingLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $loadingForm.Controls.Add($loadingLabel)

    $loadingBar = New-Object System.Windows.Forms.ProgressBar
    $loadingBar.Location = New-Object System.Drawing.Point(20, 70)
    $loadingBar.Size = New-Object System.Drawing.Size(260, 20)
    $loadingBar.Style = "Marquee"
    $loadingBar.MarqueeAnimationSpeed = 30
    $loadingForm.Controls.Add($loadingBar)

    $loadingForm.Show()
    $loadingForm.Refresh()
    return $loadingForm
}

function Install-JavaRuntime {
    $javaExe = "$javaDir\bin\java.exe"
    if (-Not (Test-Path $javaExe)) {
        $loadingForm = Show-LoadingPopup -Message "Installing Java Runtime Environment...`nThis may take a bit."
        
        $javaUrl = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jre_x64_windows_hotspot_21.0.2_13.zip"
        $javaZip = "$installDir\jre.zip"
        
        try {
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($javaUrl, $javaZip)
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($javaZip, "$javaDir\..")
            Remove-Item $javaZip
        }
        finally {
            $loadingForm.Close()
        }
    }
}

function Initialize-Launcher {
    $form.statusLabel.Text = "Initializing launcher..."
    $form.progressBar.Value = 0

    $javaExe = "$javaDir\bin\java.exe"
    if (-Not (Test-Path $javaExe)) {
        $form.statusLabel.Text = "Installing OpenJDK 21..."
        $form.progressBar.Value = 10
        $javaUrl = "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jre_x64_windows_hotspot_21.0.2_13.zip"
        $javaZip = "$installDir\jre.zip"
        Download-File -Url $javaUrl -Output $javaZip
        
        $form.statusLabel.Text = "Extracting Java..."
        $form.progressBar.Value = 30
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($javaZip, "$javaDir\..")
        Remove-Item $javaZip
    }

    $form.statusLabel.Text = "Fetching version list..."
    $form.progressBar.Value = 50
    $manifestUrl = "https://launchermeta.mojang.com/mc/game/version_manifest.json"
    $manifestFile = "$mcDir\version_manifest.json"
    Download-File -Url $manifestUrl -Output $manifestFile
    $script:manifest = Get-Content -Path $manifestFile | ConvertFrom-Json

    $releaseVersions = $manifest.versions | Where-Object { $_.type -eq "release" } | Select-Object -First 20
    $form.versionComboBox.Items.Clear()
    $releaseVersions | ForEach-Object { $form.versionComboBox.Items.Add($_.id) } | Out-Null
    $form.versionComboBox.SelectedIndex = 0

    $form.statusLabel.Text = "Ready to launch"
    $form.progressBar.Value = 100
}

function Launch-Minecraft {
    $selectedVersion = $form.versionComboBox.SelectedItem
    $username = $form.usernameTextBox.Text

    if ([string]::IsNullOrEmpty($username)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    Save-Username -username $username
    $form.launchButton.Enabled = $false
    $form.progressBar.Value = 0

    $selectedDetails = $manifest.versions | Where-Object { $_.id -eq $selectedVersion }
    $versionDir = "$versionsDir\$selectedVersion"
    $clientJarFile = "$versionDir\$selectedVersion.jar"
    $versionDetailsFile = "$versionDir\$selectedVersion.json"

    if (-Not (Test-Path $versionDir)) {
        New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
    }

    $form.statusLabel.Text = "Downloading game files..."
    $form.progressBar.Value = 20
    Download-File -Url $selectedDetails.url -Output $versionDetailsFile
    $versionDetails = Get-Content -Path $versionDetailsFile | ConvertFrom-Json
    Download-File -Url $versionDetails.downloads.client.url -Output $clientJarFile

    $form.statusLabel.Text = "Downloading libraries..."
    $form.progressBar.Value = 40
    foreach ($lib in $versionDetails.libraries) {
        if ($lib.downloads.artifact) {
            $libraryPath = "$librariesDir\$($lib.downloads.artifact.path -replace '/', '\')"
            $libraryDir = Split-Path -Parent $libraryPath
            if (-Not (Test-Path $libraryDir)) {
                New-Item -ItemType Directory -Path $libraryDir -Force | Out-Null
            }
            Download-File -Url $lib.downloads.artifact.url -Output $libraryPath
        }
    }

    $form.statusLabel.Text = "Downloading assets..."
    $form.progressBar.Value = 60
    $assetsIndexUrl = $versionDetails.assetIndex.url
    $assetsIndexFile = "$assetsIndexesDir\$($versionDetails.assetIndex.id).json"
    Download-File -Url $assetsIndexUrl -Output $assetsIndexFile
    $assetsIndex = Get-Content -Path $assetsIndexFile | ConvertFrom-Json

    $form.progressBar.Value = 80
    foreach ($key in $assetsIndex.objects.Keys) {
        $hash = $assetsIndex.objects[$key].hash
        $subDir = $hash.Substring(0, 2)
        $objectDir = "$assetsObjectsDir\$subDir"
        if (-Not (Test-Path $objectDir)) {
            New-Item -ItemType Directory -Path $objectDir -Force | Out-Null
        }
        $objectFile = "$objectDir\$hash"
        $objectUrl = "http://resources.download.minecraft.net/$subDir/$hash"
        Download-File -Url $objectUrl -Output $objectFile
    }

    $form.statusLabel.Text = "Launching game..."
    $form.progressBar.Value = 90

    $cp = New-Object System.Collections.ArrayList
    foreach ($lib in $versionDetails.libraries) {
        if ($lib.downloads.artifact) {
            $libraryPath = "$librariesDir\$($lib.downloads.artifact.path -replace '/', '\')"
            $cp.Add($libraryPath) | Out-Null
        }
    }
    $cp.Add($clientJarFile) | Out-Null
    $classpath = $cp -join ";"

    $launchArgs = @(
        "-Xmx2G"
        "-Djava.library.path=$nativesDir"
        "-cp", $classpath
        $versionDetails.mainClass
        "--username", $username
        "--version", $selectedVersion
        "--gameDir", $mcDir
        "--assetsDir", $assetsDir
        "--assetIndex", $versionDetails.assetIndex.id
        "--uuid", (New-Guid).ToString()
        "--accessToken", "0"
        "--clientId", "0"
        "--xuid", "0"
        "--userProperties", "{}"
        "--userType", "legacy"
    )

    $javaExe = "$javaDir\bin\java.exe"
    Start-Process -FilePath $javaExe -ArgumentList $launchArgs -NoNewWindow

    $form.progressBar.Value = 100
    $form.launchButton.Enabled = $true
}

Install-JavaRuntime

$form = New-Object System.Windows.Forms.Form
$form | Add-Member -MemberType NoteProperty -Name usernameTextBox -Value $null
$form | Add-Member -MemberType NoteProperty -Name versionComboBox -Value $null
$form | Add-Member -MemberType NoteProperty -Name launchButton -Value $null
$form | Add-Member -MemberType NoteProperty -Name progressBar -Value $null
$form | Add-Member -MemberType NoteProperty -Name statusLabel -Value $null

$form.Text = "ClassCraft"
$form.Size = New-Object System.Drawing.Size(800, 450)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White

$usernameLabel = New-Object System.Windows.Forms.Label
$usernameLabel.Location = New-Object System.Drawing.Point(20, 20)
$usernameLabel.Size = New-Object System.Drawing.Size(100, 20)
$usernameLabel.Text = "Username:"
$usernameLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($usernameLabel)

$usernameTextBox = New-Object System.Windows.Forms.TextBox
$usernameTextBox.Location = New-Object System.Drawing.Point(120, 20)
$usernameTextBox.Size = New-Object System.Drawing.Size(200, 20)
$usernameTextBox.Text = Get-SavedUsername
$form.usernameTextBox = $usernameTextBox
$form.Controls.Add($usernameTextBox)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Location = New-Object System.Drawing.Point(20, 60)
$versionLabel.Size = New-Object System.Drawing.Size(100, 20)
$versionLabel.Text = "Version:"
$versionLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($versionLabel)

$versionComboBox = New-Object System.Windows.Forms.ComboBox
$versionComboBox.Location = New-Object System.Drawing.Point(120, 60)
$versionComboBox.Size = New-Object System.Drawing.Size(200, 20)
$versionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.versionComboBox = $versionComboBox
$form.Controls.Add($versionComboBox)


$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Location = New-Object System.Drawing.Point(120, 100)
$launchButton.Size = New-Object System.Drawing.Size(200, 40)
$launchButton.Text = "Launch Game"
$launchButton.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$launchButton.ForeColor = [System.Drawing.Color]::White
$launchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$launchButton.FlatAppearance.BorderSize = 0

$path = [System.Drawing.Drawing2D.GraphicsPath]::new()
$radius = 20
$path.AddArc(0, 0, $radius, $radius, 180, 90)
$path.AddArc($launchButton.Width - $radius, 0, $radius, $radius, 270, 90)
$path.AddArc($launchButton.Width - $radius, $launchButton.Height - $radius, $radius, $radius, 0, 90)
$path.AddArc(0, $launchButton.Height - $radius, $radius, $radius, 90, 90)
$path.CloseFigure()
$launchButton.Region = [System.Drawing.Region]::new($path)

$launchButton.Add_Click({ Launch-Minecraft })
$form.launchButton = $launchButton
$form.Controls.Add($launchButton)

$settingsButton = New-Object System.Windows.Forms.Button
$settingsButton.Location = New-Object System.Drawing.Point(20, 100)
$settingsButton.Size = New-Object System.Drawing.Size(80, 40)
$settingsButton.Text = "Settings"
$settingsButton.BackColor = [System.Drawing.Color]::FromArgb(64, 64, 64)
$settingsButton.ForeColor = [System.Drawing.Color]::White
$settingsButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$settingsButton.FlatAppearance.BorderSize = 0

$path = [System.Drawing.Drawing2D.GraphicsPath]::new()
$radius = 20
$path.AddArc(0, 0, $radius, $radius, 180, 90)
$path.AddArc($settingsButton.Width - $radius, 0, $radius, $radius, 270, 90)
$path.AddArc($settingsButton.Width - $radius, $settingsButton.Height - $radius, $radius, $radius, 0, 90)
$path.AddArc(0, $settingsButton.Height - $radius, $radius, $radius, 90, 90)
$path.CloseFigure()
$settingsButton.Region = [System.Drawing.Region]::new($path)

$settingsButton.Add_Click({ Start-Process $installDir })
$form.Controls.Add($settingsButton)



$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 160)
$progressBar.Size = New-Object System.Drawing.Size(740, 20)
$progressBar.Style = "Continuous"
$form.progressBar = $progressBar
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 190)
$statusLabel.Size = New-Object System.Drawing.Size(740, 20)
$statusLabel.Text = "Ready"
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.statusLabel = $statusLabel
$form.Controls.Add($statusLabel)

Initialize-Launcher
$form.ShowDialog()