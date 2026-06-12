Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ConsoleFont {
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct CONSOLE_FONT_INFO_EX {
		public uint cbSize;
		public uint nFont;
		public short dwFontSizeX;
		public short dwFontSizeY;
		public int FontFamily;
		public int FontWeight;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
		public string FaceName;
	}
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr GetStdHandle(int nStdHandle);
	public static void SetFont(string fontName, short fontSize = 12) {
		IntPtr hConsole = GetStdHandle(-11); // STD_OUTPUT_HANDLE
		CONSOLE_FONT_INFO_EX fontInfo = new CONSOLE_FONT_INFO_EX();
		fontInfo.cbSize = (uint)Marshal.SizeOf(fontInfo);
		fontInfo.FaceName = fontName;
		fontInfo.dwFontSizeY = fontSize;
		SetCurrentConsoleFontEx(hConsole, false, ref fontInfo);
	}
}
"@

# Подключение системных сборок для работы с Zip-архивами (чтение Info.plist):
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Устанавливаем шрифт Consolas и кодировку UTF8:
[ConsoleFont]::SetFont("Consolas", 16)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# Версия скрипта:
Write-Host "IPA_Installer 1.0.1" -ForegroundColor Black -BackgroundColor Yellow

# Файл языка скрипта:
$LangConfigFile = ".\MainApp\Lang_Config.txt"
$Global:CurrentLang = "RU"

# Загрузка сохраненного языка или установка по умолчанию:
if (Test-Path $LangConfigFile) {
	$SavedLang = (Get-Content $LangConfigFile -Raw).Trim().ToUpper()
	if ($SavedLang -match '^(RU|EN)$') {
		$Global:CurrentLang = $SavedLang
	}
} else {
	Set-Content -Path $LangConfigFile -Value $Global:CurrentLang -Force
}

# Перевод текста:
$LangStrings = @{
	"RU" = @{
		"AskAppNum" = "Введите номера приложений"
		"CancelStep" = "(0: Отмена/Возврат в главное меню)"
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorMissingFiles" = "Ошибка: Следующие файлы не найдены в папке MainApp:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"HeaderFileName" = "Имя файла"
		"HeaderMinIOS" = "Мин. iOS"
		"InstallApp" = "Установка:"
		"LangChanged" = "Язык успешно изменен на Русский."
		"MenuTitle" = "Введите команду:"
		"Menu1" = "1. Установка приложений из папки Apps"
		"Menu2" = "2. Проверка минимальной версии iOS для приложений в папке Apps"
		"Menu3" = "3. Сменить язык (Change Language)"
		"PressEnter" = "Нажмите Enter для выхода"
	}
	"EN" = @{
		"AskAppNum" = "Enter index numbers of apps"
		"CancelStep" = "(0: Cancel/Return to main menu)"
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorMissingFiles" = "Error: Following files were not found in MainApp folder:"
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"HeaderFileName" = "File name"
		"HeaderMinIOS" = "Min. iOS"
		"InstallApp" = "Installing:"
		"LangChanged" = "Language successfully changed to English."
		"MenuTitle" = "Enter a command:"
		"Menu1" = "1. Install apps from Apps folder"
		"Menu2" = "2. Check minimum iOS version for apps in Apps folder"
		"Menu3" = "3. Change Language (Сменить язык)"
		"PressEnter" = "Press Enter to exit"
	}
}

# Функция перевода текста:
function Get-Lang($Key) {
	return $LangStrings[$Global:CurrentLang][$Key]
}

# Функция разделителя:
function Separator {
	Write-Host "================================================" -ForegroundColor Green
}

# Проверка на наличие базовых папок:
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}

# Проверка на наличие ideviceinstaller.exe:
$CheckMainAppFiles = @("ideviceinstaller.exe")
$MissingMainAppFiles = @()
foreach ($File in $CheckMainAppFiles) {
	if (!(Test-Path ".\MainApp\$File")) {
		$MissingMainAppFiles += $File
	}
}
if ($MissingMainAppFiles.Count -gt 0) {
	Separator
	Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor DarkRed
	$MissingMainAppFiles | ForEach-Object { Write-Host "$_" -ForegroundColor DarkRed }
	Separator
	Read-Host (Get-Lang "PressEnter")
	exit
}

# Универсальная функция извлечения метаданных из IPA:
function Get-IPA-Metadata {
	param ([string]$IpaPath)
	if (!(Test-Path $IpaPath)) { return $null }
	
	$Metadata = [PSCustomObject]@{
		AppName = "App"
		Version = "0"
		MinIOS = "NA"
	}
	
	try {
		$Zip = [System.IO.Compression.ZipFile]::OpenRead($IpaPath)
		$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match 'Payload/.*\.app/Info\.plist$' } | Select-Object -First 1
		if ($PlistEntry) {
			try {
				$Reader = New-Object System.IO.StreamReader($PlistEntry.Open(), [System.Text.Encoding]::UTF8)
				$Content = $Reader.ReadToEnd()
			} finally {
				if ($null -ne $Reader) { $Reader.Dispose() }
			}
			
			if ($Content -match '<key>CFBundleName</key>\s*<string>([^<]+)</string>') {
				$Metadata.AppName = $Matches[1]
			}
			if (($Metadata.AppName -eq "App") -and ($Content -match '<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>')) {
				$Metadata.AppName = $Matches[1]
			}
			if ($Content -match '<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>') {
				$Metadata.Version = $Matches[1]
			}
			if ($Content -match '<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>') {
				$Metadata.MinIOS = $Matches[1]
			}
		}
	} catch {
		return $null
	} finally {
		if ($null -ne $Zip) {
			$Zip.Dispose()
		}
	}
	
	$Metadata.AppName = $Metadata.AppName -replace '[\\/:*?"<>|]', ''
	return $Metadata
}

# Универсальная функция для парсинга введенных номеров и диапазонов:
function Parse-NumberSelection {
	param (
		[string]$Selection,
		[int]$MaxCount
	)
	$SelectedIndices = @()
	$Parts = $Selection -split ','

	foreach ($Part in $Parts) {
		$Part = $Part.Trim()
		if ($Part -match '^\d+-\d+$') {
			$Range = $Part -split '-'
			$Start = 0; $End = 0
			if (![int]::TryParse($Range[0], [ref]$Start) -or ![int]::TryParse($Range[1], [ref]$End)) { return $null }
			if ($Start -le $End) { $SelectedIndices += $Start..$End } else { $SelectedIndices += $End..$Start }
		} elseif ($Part -match '^\d+$') {
			$Val = 0
			if (![int]::TryParse($Part, [ref]$Val)) { return $null }
			$SelectedIndices += $Val
		} else {
			return $null
		}
	}

	$SelectedIndices = $SelectedIndices | Select-Object -Unique | Where-Object { $_ -ge 1 -and $_ -le $MaxCount }
	
	if ($SelectedIndices.Count -eq 0) { return $null }
	return $SelectedIndices
}

# Функция проверки минимальной версии iOS:
function Get-iOS-MinVersion {
	$FilesToProcess = Get-ChildItem -Path ".\Apps\*.ipa" -ErrorAction SilentlyContinue
	if (-not $FilesToProcess) {
		Separator
		Write-Host (Get-Lang "ErrorNoApps") -ForegroundColor DarkRed
		return
	}
	Separator
	Write-Host ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderFileName"), (Get-Lang "HeaderMinIOS"))
	$Counter = 1
	foreach ($File in $FilesToProcess) {
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "Error" }
		$PrintName = if ($File.Name.Length -gt 30) { $File.Name.Substring(0,27) + "..." } else { $File.Name }
		Write-Host ("{0,-3} {1,-30} {2}" -f $Counter, $PrintName, $MinOs)
		$Counter++
	}
}

# Основной цикл меню:
while ($true) {
	Separator
	$MainMenu = @"
$(Get-Lang 'MenuTitle')
$(Get-Lang 'Menu1')
$(Get-Lang 'Menu2')
$(Get-Lang 'Menu3')`n
"@

	$SwitchValue = Read-Host $MainMenu
	switch ($SwitchValue) {
		# 1. Установка приложений из папки Apps:
		"1" {
			$IpaFiles = @(Get-ChildItem -Path ".\Apps\*.ipa" -ErrorAction SilentlyContinue)
			
			if ($IpaFiles.Count -gt 0) {
				Separator
				Write-Host ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderFileName"), (Get-Lang "HeaderMinIOS"))
				
				# Выводим пронумерованный список файлов с версией iOS:
				$Counter = 1
				foreach ($File in $IpaFiles) {
					$Meta = Get-IPA-Metadata -IpaPath $File.FullName
					$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "Error" }
					$PrintName = if ($File.Name.Length -gt 30) { $File.Name.Substring(0,27) + "..." } else { $File.Name }
					Write-Host ("{0,-3} {1,-30} {2}" -f $Counter, $PrintName, $MinOs)
					$Counter++
				}
				Separator
				
				# Запрашиваем номера для установки с возможностью отмены:
				$Selection = Read-Host "$(Get-Lang 'AskAppNum') (1-$($IpaFiles.Count)) $(Get-Lang 'CancelStep')`n"
				
				if ($Selection -eq '0') { continue }
				if ([string]::IsNullOrWhiteSpace($Selection)) {
					Separator
					Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor DarkRed
					continue
				}

				# Обрабатываем ввод пользователя через функцию:
				$SelectedIndices = Parse-NumberSelection -Selection $Selection -MaxCount $IpaFiles.Count
				
				if ($null -eq $SelectedIndices) {
					Separator
					Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor DarkRed
					continue
				}

				# Устанавливаем выбранные приложения:
				foreach ($Idx in $SelectedIndices) {
					$SelectedFile = $IpaFiles[$Idx - 1]
					Separator	
					Write-Host "$(Get-Lang 'InstallApp') $($SelectedFile.Name)$MinOsSuffix"
					$TempFile = "$env:TEMP\Temp.ipa"
					Copy-Item -Path $SelectedFile.FullName -Destination $TempFile -Force
					.\MainApp\ideviceinstaller.exe install $TempFile
					Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
				}
			} else {
				Separator
				Write-Host (Get-Lang "ErrorNoApps") -ForegroundColor DarkRed
			}
		}
		
		# 2. Проверка минимальной версии iOS для приложений в папке Apps:
		"2" {
			Get-iOS-MinVersion
		}

		# 3. Сменить язык (Change Language):
		"3" {
			$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
			Set-Content -Path $LangConfigFile -Value $Global:CurrentLang -Force
			Separator
			Write-Host (Get-Lang "LangChanged")
		}
		
		# Неверный ввод:
		default {
			Separator
			Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor DarkRed
		}
	}
}
