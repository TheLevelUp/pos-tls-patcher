# LevelUp TLS 1.2 Patcher
A simple installer which makes .NET 4.x code use [Transport Layer Security](https://en.wikipedia.org/wiki/Transport_Layer_Security) (TLS) 1.2 without any code changes by doing the following:

* Detects whether .NET 4.6 or higher is present on the system, and if not, downloads and installs the .NET 4.6 Redistributable.
* Writes a registry value which makes .NET 4.x code select the strongest enabled security protocol by default.
* Writes registry values to explicitly enable TLS 1.2 for [WinSSL](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380123(v=vs.85).aspx).

For the rationale behind these changes, see [Details of changes made by the patcher](#details-of-changes-made-by-the-patcher). 

Some exceptions may apply. See [Limitations](#limitations) for details

## Download
Make sure to use the version which matches your architecture: 
* [x86](#TODO) for 32-bit versions of Windows
* [x64](#TODO) for 64-bit versions of Windows. 

### System Requirements
To install:
* Minimum: Windows Vista Service Pack 2

To build:
* [Wix Toolset v3.11](http://wixtoolset.org/releases/)

### Installation
To install, simply run the installer and accept the license agreement. You must have administrative priveledges. You will be prompted to restart your computer in order for the changes to take effect.

## Table of Contents
- [LevelUp TLS 1.2 Patcher](#levelup-tls-12-patcher)
    - [Download](#download)
        - [System Requirements](#system-requirements)
        - [Installation](#installation)
    - [Table of Contents](#table-of-contents)
    - [Details of changes made by the patcher](#details-of-changes-made-by-the-patcher)
        - [.NET Framework Version](#net-framework-version)
        - [.NET Framework registry keys](#net-framework-registry-keys)
        - [SChannel registry keys](#schannel-registry-keys)
    - [Usage](#usage)
    - [Limitations](#limitations)
    - [License](#license)

## Details of changes made by the patcher
### .NET Framework Version
The option of using TLS 1.2 was introduced in .NET 4.5, however, it is not enabled as a communication protocol by default in 4.5. Beginning with .NET 4.6, it is enabled as a communication protocol by default. Thus, in conjunction with the appropriate registry changes, .NET 4.6+ makes it possible to use TLS 1.2 without having to make code changes to explicitly enable it.

### .NET Framework registry keys
In order to make .NET 4.x code select the strongest available protocol by default (i.e. when a protocol is not explicitly specified in code), the following registry keys are set:

On 32-bit versions of Windows:

| Registry Key                                    | Value Name         | DWORD Data |
| ----------------------------------------------- | ------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\.NETFramework\4.0.30319 | SchUseStrongCrypto | 0x00000001 |

On 64-bit versions of Windows:

| Registry Key                                                | Value Name         | DWORD Data |
| ----------------------------------------------------------- | ------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\.NETFramework\4.0.30319             | SchUseStrongCrypto | 0x00000001 |
| HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\4.0.30319 | SchUseStrongCrypto | 0x00000001 |

The [WOW6432Node](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724072(v=vs.85).aspx) value is used by 32-bit applications when run on a 64-bit system. If you happened to run the x86 patcher on a 64-bit system instead of the x64 patcher, then only the WOW6432Node value would be added to the registry. In this case, 32-bit .NET 4.x applications would show the expected change in behavior and use TLS 1.2, but 64-bit applications will not. For this reason, the x86 installer will abort if it detects it is running on a 64-bit system, and the x64 installer should be used instead.

### SChannel registry keys
The following registry keys/values are set to enable the TLS 1.2 for SChannel.dll (aka WinSSL). If these values do not exist, the default behavior when using the SchUseStrongCrypto key with .NET 4.6+ should still select TLS 1.2. However, we explicitly set the keys in order to avoid any issues which may arise if any of the keys already exist with contradictory values.  

| Registry Key                                                                              | Value Name        | DWORD Data |
| ----------------------------------------------------------------------------------------- | ----------------- | ---------- |
| HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client     | Enabled           | 0x00000001 |
| HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client     | DisabledByDefault | 0x00000000 |
| HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server     | Enabled           | 0x00000001 |
| HKLM\SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server     | DisabledByDefault | 0x00000000 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client | Enabled           | 0x00000001 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client | DisabledByDefault | 0x00000000 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server | Enabled           | 0x00000001 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server | DisabledByDefault | 0x00000000 |

## Usage
If you wish to include this patch as part of an installer, you can modify [Bundle.wxs](LevelUp.Integrations.TlsPatcher/LevelUp.Integrations.TlsPatcher.Bootstrapper/Bundle.wxs) to include your installer as an additional package element within the [Chain](http://wixtoolset.org/documentation/manual/v3/xsd/wix/chain.html) element. 

If you want to include just the registry changes in a Wix Installer project, you can add a reference to [Tls12RegistryComponents.wxi](LevelUp.Integrations.TlsPatcher/LevelUp.Integrations.TlsPatcher.Installer/Tls12RegistryComponents.wxi) file and [add an include statement in your Product.wxs file](LevelUp.Integrations.TlsPatcher/LevelUp.Integrations.TlsPatcher.Installer/Product.wxs#L84). 

## Limitations
The patcher is expected to work for .NET 4.x code provided that the current code is not overriding the defaults by explicitly specifying a different protocol. If this is not the case, code changes will be necessary. If you wish to make use of this patcher, you can simply remove any lines where you set the value of `ServicePointManager.SecurityProtocol`.

The [Schannel registry keys](#schannel-registry-keys) described may also work for non-.NET code that uses WinSSL and does not explicitly specify a non-TLS 1.2 protocol.

The following are some resources for other scenarios which we have not tested, but may be useful:

* If you wish to continue explicitly setting the protocol in code [this stackoverflow thread](https://stackoverflow.com/questions/33761919/tls-1-2-in-net-framework-4-0/39725273) offers guidance for .NET 4.0/4.5

* If you are targeting an older version of .NET, Microsoft has provided updates to add TLS 1.2 support in [.NET 3.5](https://support.microsoft.com/en-us/help/3154520/support-for-tls-system-default-versions-included-in-the-net-framework) and [.NET 2.0](https://support.microsoft.com/en-us/help/3154517/support-for-tls-system-default-versions-included-in-the-net-framework)

## License
This project is licensed under the Apache 2.0 License - see the [LICENSE.txt](LICENSE.txt) file for details.