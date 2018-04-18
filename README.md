# LevelUp TLS Patcher

A simple installer which enables [Transport Layer Security](https://en.wikipedia.org/wiki/Transport_Layer_Security) (TLS) 1.2 on Microsoft Windows Vista Service Pack 2 or later.

The patcher is designed to make .NET 4.x applications use TLS 1.2 without needing any code changes. It may also work for some applications targeting lower version of .NET.

<!-- TOC -->

- [LevelUp TLS Patcher](#levelup-tls-patcher)
    - [Download and Installation](#download-and-installation)
    - [Compatibility](#compatibility)
    - [In-Depth](#in-depth)
        - [.NET Framework Version](#net-framework-version)
        - [.NET Framework registry keys](#net-framework-registry-keys)
            - [.NET 4.x](#net-4x)
            - [.NET 3.5 and lower](#net-35-and-lower)
            - [Note on 32-bit vs 64-bit registry values](#note-on-32-bit-vs-64-bit-registry-values)
        - [SChannel registry keys](#schannel-registry-keys)
    - [Build Requirements](#build-requirements)
        - [Certificate Signing](#certificate-signing)
        - [Build Instructions](#build-instructions)
    - [Usage](#usage)
    - [Limitations](#limitations)
    - [License](#license)

<!-- /TOC -->

## Download and Installation
[The latest version can be downloaded here](../../releases/latest).

To install, simply run the installer and accept the license agreement. You must have administrative privileges. You may be prompted to restart your computer in order for the changes to take effect.

Minimum system requirements:
* For one-click install with no other prerequisites: Windows 7 with Service Pack 1
* Windows Vista SP2 and Windows Server 2008 SP2 are supported after installing [Microsoft Update KB4019276](https://www.catalog.update.microsoft.com/Search.aspx?q=KB4019276).

The installer:

* Detects whether .NET 4.6 or higher is present on the system, and if not, downloads and installs the .NET 4.6 Redistributable.
* Writes a registry value which makes .NET 4.x code select the strongest enabled security protocol by default.
* Writes registry values to explicitly enable TLS 1.2 for [WinSSL](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380123(v=vs.85).aspx).

The patcher will appear in Add/Remove Programs. Uninstalling the patcher will delete the registry values it created, potentially disabling TLS 1.2. Uninstalling the patcher will not uninstall .NET 4.6. 

For the rationale behind these changes, see the [in-depth](#in-depth) section below. 

Some exceptions may apply. See the [limitations](#limitations) section below.

## Compatibility

See the table below for a list of systems verified to be compatible/incompatible with this utility. Cells which do not have an X or ✓ have not yet been tested, but we expect them to be compatible unless otherwise noted. N/A indicates that the Windows version does not have a release with the specified architecture.

| Windows OS                                                 | x86 | x64 | Notes                     |
| ---------------------------------------------------------- | --- | --- | ------------------------- |
| Windows XP & Windows Server 2003                           | X   | X   | Does not support .NET 4.6 |
| Windows Embedded Point of Sale 1.0                         | X   | X   | Does not support .NET 4.6 |
| Windows Embedded POSReady 2009                             | X   | N/A | Does not support .NET 4.6 |
| Windows Vista with Service Pack 2 (SP2)                    |     | ✓   | Requires KB4019276        |
| Windows Server 2008 with Service Pack 2 (SP2)              | N/A | ✓   | Requires KB4019276        |
| Windows 7/Windows Server 2008 R2 with Service Pack 1 (SP1) | ✓   | ✓   |                           |
| Windows Embedded POSReady 7                                | ✓   |     |                           |
| Windows 8/Windows Server 2012                              | ✓   | ✓   |                           |
| Windows Embedded 8 Industry                                |     |     |                           |
| Windows 8.1/Windows Server 2012 R2                         | ✓   | ✓   |                           |
| Windows Embedded 8.1 Industry                              | ✓   |     |                           |
| Windows 10 & Windows Server 2016                           | ✓   | ✓   |                           |

## In-Depth
This section outlines in more detail what changes are made.

### .NET Framework Version
The option of using TLS 1.2 was introduced in .NET 4.5, however, it is not enabled as a communication protocol by default in 4.5. Beginning with .NET 4.6, it is enabled as a communication protocol by default. Thus, in conjunction with the appropriate registry changes, .NET 4.6+ makes it possible to use TLS 1.2 without having to make code changes to explicitly enable it.

### .NET Framework registry keys
#### .NET 4.x
In order to make .NET 4.x code select the strongest available protocol by default (i.e. when a protocol is not explicitly specified in code), the following registry keys are set:

On 32-bit versions of Windows:

| Registry Key                                     | Value Name         | DWORD Data |
| ------------------------------------------------ | ------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\\.NETFramework\4.0.30319 | SchUseStrongCrypto | 0x00000001 |

On 64-bit versions of Windows:

| Registry Key                                                 | Value Name         | DWORD Data |
| ------------------------------------------------------------ | ------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\\.NETFramework\4.0.30319             | SchUseStrongCrypto | 0x00000001 |
| HKLM\SOFTWARE\WOW6432Node\Microsoft\\.NETFramework\4.0.30319 | SchUseStrongCrypto | 0x00000001 |

#### .NET 3.5 and lower
The following registry values may enable TLS 1.2 for apps targeting lower versions of .NET on some systems in conjunction with certain updates (see [Limitations](#limitations) for details)

On 32-bit versions of Windows:

| Registry Key                                     | Value Name               | DWORD Data |
| ------------------------------------------------ | ------------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\\.NETFramework\2.0.50727 | SystemDefaultTlsVersions | 0x00000001 |

On 64-bit versions of Windows:

| Registry Key                                                 | Value Name               | DWORD Data |
| ------------------------------------------------------------ | ------------------------ | ---------- |
| HKLM\SOFTWARE\Microsoft\\.NETFramework\2.0.50727             | SystemDefaultTlsVersions | 0x00000001 |
| HKLM\SOFTWARE\WOW6432Node\Microsoft\\.NETFramework\2.0.50727 | SystemDefaultTlsVersions | 0x00000001 |

#### Note on 32-bit vs 64-bit registry values
The [WOW6432Node](https://msdn.microsoft.com/en-us/library/windows/desktop/ms724072(v=vs.85).aspx) values are used by 32-bit applications when run on a 64-bit system. If you happened to run the .msi generated by the Installer.x86 project on a 64-bit system, then only the WOW6432Node values would be added to the registry. In this case, 32-bit .NET 4.x applications would show the expected change in behavior and use TLS 1.2, but 64-bit applications would not. For this reason, we provide only the .exe file generated by the Bootstrapper project as a download. The bootstrapper is bundled with both x86 and x64 .msi files. It will detect whether the system is 32-bit or 64-bit and run the appropriate .msi.

### SChannel registry keys
The following registry keys/values are set to enable the TLS 1.2 for SChannel.dll (aka WinSSL). If these values do not exist, the default behavior when using the SchUseStrongCrypto key with .NET 4.6+ should still select TLS 1.2. However, we explicitly set the keys in order to avoid any issues which may arise if any of the keys already exist with contradictory values.  

| Registry Key                                                                              | Value Name        | DWORD Data |
| ----------------------------------------------------------------------------------------- | ----------------- | ---------- |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client | Enabled           | 0x00000001 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client | DisabledByDefault | 0x00000000 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server | Enabled           | 0x00000001 |
| HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server | DisabledByDefault | 0x00000000 |

## Build Requirements
To build this Visual Studio solution (`.sln`) you must have the following components installed:

* Visual Studio 2017/MSBuild 15.0
* Powershell
* NuGet CLI - The nuget command must be available from your command line.
* [WiX Toolset v3.11](http://wixtoolset.org/releases/)

### Certificate Signing
LevelUp signs its installers by hooking into MSBuild. If you build this project on your own machine, you may ignore the following warning message:

> warning : The LevelUp certificate cannot be found; no files will be signed.

### Build Instructions
`git clean -fdx`

`nuget.exe restore LevelUp.Integrations.TlsPatcher.sln`

`MSBuild.exe LevelUp.Integrations.TlsPatcher.sln /p:Configuration=<Debug/Release>`

For convenience, the build process will create a folder named Deployment in the root directory, and the outputted files will be copied there. 

## Usage
If you wish to include the TLS Patcher as part of an installer, you can include it as part of a WiX Bootstrapper. 

To facilitate this, beginning with v1.1.0, the patcher writes a set of registry values which can be used to detect what version, if any, is currently installed on a system. The version information can be used in the `DetectCondition` of the [ExePackage](http://wixtoolset.org/documentation/manual/v3/xsd/wix/exepackage.html) definition so that the patcher installation will be suppressed if the same or higher version already exists on the system.

The following code snippet shows how you could include v1.1.0 of the TLS Patcher  in a bootstrapper project, assuming that the .exe is placed in a folder named "Dependencies" within the bootstraper project.

```xml
<Bundle>
    <!-- ... -->

    <Chain DisableSystemRestore="no">

      <PackageGroupRef Id="TlsPatcher" />

      <!--Other packages-->

    </Chain>

</Bundle>

<Fragment>
    <?define BundledTlsPatcherVersion="1.1.0"?>

    <util:RegistrySearch Root="HKLM" Key="SOFTWARE\LevelUp" Value="TlsPatcherVersion"
                            Format="raw" Win64="no" Variable="ExistingTlsPatcherVersion" />

    <util:RegistrySearch Root="HKLM" Key="SOFTWARE\LevelUp" Value="TlsPatcherVersion"
                            Format="raw" Win64="yes" Variable="ExistingTlsPatcherVersion64" />

    <Variable Name="BundledTlsPatcherVersion" Value="$(var.BundledTlsVersion)" Type="version"/>
        
    <PackageGroup Id="TlsPatcher">
        <ExePackage
        Id="TlsPatcher"
        Name="TlsPatcher-$(var.BundledTlsPatcherVersion).exe"
        SourceFile="$(var.ProjectDir)Dependencies\TlsPatcher-$(var.BundledTlsPatcherVersion).exe"
        DetectCondition="ExistingTlsPatcherVersion &gt;= BundledTlsPatcherVersion AND (NOT VersionNT64 OR ExistingTlsPatcherVersion64 &gt;= BundledTlsPatcherVersion)"
        InstallCommand="/q"
        RepairCommand="/q /repair"
        PerMachine="yes"
        Vital="yes"
        Permanent="yes"
        Compressed="yes" />
    </PackageGroup>
</Fragment>    
```

## Limitations
The patcher is expected to work for .NET 4.x code provided that the current code is not overriding the defaults by explicitly specifying a different protocol. If this is not the case, code changes will be necessary. If you wish to make use of this patcher, you can simply remove any lines where you set the value of `ServicePointManager.SecurityProtocol`.

The [Schannel registry keys](#schannel-registry-keys) described may also work for non-.NET code that uses WinSSL and does not explicitly specify a non-TLS 1.2 protocol.

The following are some resources for other scenarios which we have not tested, but may be useful:

* If you wish to continue explicitly setting the protocol in code [this stackoverflow thread](https://stackoverflow.com/questions/33761919/tls-1-2-in-net-framework-4-0/39725273) offers guidance for .NET 4.0/4.5

* If you are targeting an older version of .NET, Microsoft has provided the following updates to support the SystemDefaultTlsVersions registry key:
    * [.NET 2.0 on Vista SP2 and Server 2008 SP2](https://support.microsoft.com/en-us/help/3154517/support-for-tls-system-default-versions-included-in-the-net-framework)
    * [.NET 3.5.1 on Windows 7 SP1 and Server 2008 R2 SP1](https://support.microsoft.com/en-us/help/3154518/support-for-tls-system-default-versions-included-in-the-net-framework)
    * [.NET 3.5 on Windows Server 2012](https://support.microsoft.com/en-us/help/3154519/support-for-tls-system-default-versions-included-in-the-net-framework)
    * [.NET 3.5 on Windows 8.1 and Windows Server 2012 R2](https://support.microsoft.com/en-us/help/3154520/support-for-tls-system-default-versions-included-in-the-net-framework)

## License
This project is licensed under the Apache 2.0 License - see the [LICENSE.txt](LICENSE.txt) file for details.