[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Installer.svg?label=Release)](https://github.com/kda2495/IPA_Installer.svg/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Installer.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Installer.svg/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Installer.svg/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Installer.svg/releases)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A PowerShell-script for installing .ipa-files on Apple devices (powered by ideviceinstaller).

## Requirements:
• Windows 7-11 x64  
• Installed AppleMobileDeviceSupport driver (included with iTunes):  
[iTunes Download Link](https://www.apple.com/itunes/download/win64)  
Instead of installing the full iTunes package, you can perform a custom installation of `AppleMobileDeviceSupport64.msi` by extracting the iTunes installer using any archive manager.  

## How to use:
**1\. Copy .ipa-files to `IPA_Installer\Apps\`**  
**2\. Double-click the `Start_IPA_Installer.bat` file.**  

## Script Commands Overview:
#### 1. Install apps downloaded to the Apps folder
• Make sure you have iTunes installed from the official Apple website, or the `AppleMobileDeviceSupport` driver package (bundled with iTunes)  
• Connect your device to the PC via USB and trust the computer  
• To install, enter the apps' index numbers (multiple apps input is supported, eg: 1, 2, 3-5)  

#### 2. Show minimum iOS version for ipa files in Apps folder
• The script will display the minimum iOS version required for installation for all `.ipa` files currently located in the `Apps` folder  

#### 3. Change Language (Сменить язык)
• Toggles the script interface language  

## Support the Project:
IPA_Installer is completely free. However, if you wish to support the project voluntarily, you can do so using the following details:  
[Support via CloudTips](https://pay.cloudtips.ru/p/e6f6c3f8)

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/231ada77-50c9-4dfb-add2-e5da77d4b345" />
