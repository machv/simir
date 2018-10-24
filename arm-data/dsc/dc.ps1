Configuration FeaturePrereqs
{
	WindowsFeature DNS
	{
		Ensure = "Present"
		Name = "DNS"
	}
 
	WindowsFeature AD-Domain-Services
	{
		Ensure = "Present"
		Name = "AD-Domain-Services"
		DependsOn = "[WindowsFeature]DNS"
	}

	WindowsFeature DnsTools
	{
		Ensure = "Present"
		Name = "RSAT-DNS-Server"
		DependsOn = "[WindowsFeature]DNS"
	}

	WindowsFeature RSAT-ADDS
	{
		Ensure = "Present"
		Name = "RSAT-ADDS"
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}

	WindowsFeature RSAT-AD-Tools
	{
		Name = 'RSAT-AD-Tools'
		Ensure = 'Present'
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}
}
<#
Configuration JoinDomain
{
	xComputer JoinDomain
	{
		Name = ($DCPrefix + $i.ToString().PadLeft(2, '0'))
		DomainName = $DomainDnsName
		Credential = $DomainAdministratorCredentials
		DependsOn = "[xWaitForADDomain]WaitForPrimaryDC"
	}
}
#>

Configuration ConfigureServer
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCredentials,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    )
	 
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName 'xActiveDirectory'
    Import-DscResource -ModuleName 'xPendingReboot'

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("$($DomainName)\$($AdminCredentials.UserName)", $AdminCredentials.Password)

	Node localhost
    {
        FeaturePrereqs Prereq
        {
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

		xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
        }

		xADDomainController BDC
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        xPendingReboot RebootAfterPromotion 
        {
            Name = "RebootAfterDCPromotion"
            DependsOn = "[xADDomainController]BDC"
        }
	}
}


<#
Configuration JoinWorkGroupAndAddUser
{
    import-dscResource -moduleName PsDesiredStateConfiguration
    import-dscResource -moduleName xComputerManagement

    xComputer ComputerNameAndWorkgroup
    {
        Name = $node.NewNodeName

    }

    user LocalUser
    {
        UserName = $node.LocalAdmin
        Description = $node.LocalAdminDescription
        Ensure = 'Present'
        FullName = $node.LocalAdminFullName
        Password = $node.LocalAdminPassword
        PasswordNeverExpires = $true
        PasswordChangeRequired = $false
        DependsOn = "[xComputer]ComputerNameAndWorkgroup"
    }
}

Configuration FeaturePrereqs
{
	WindowsFeature DNS
	{
		Ensure = "Present"
		Name = "DNS"
	}
 
	WindowsFeature AD-Domain-Services
	{
		Ensure = "Present"
		Name = "AD-Domain-Services"
		DependsOn = "[WindowsFeature]DNS"
	}

	WindowsFeature DnsTools
	{
		Ensure = "Present"
		Name = "RSAT-DNS-Server"
		DependsOn = "[WindowsFeature]DNS"
	}

	WindowsFeature RSAT-ADDS
	{
		Ensure = "Present"
		Name = "RSAT-ADDS"
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}

	WindowsFeature RSAT-AD-Tools
	{
		Name = 'RSAT-AD-Tools'
		Ensure = 'Present'
		DependsOn = "[WindowsFeature]AD-Domain-Services"
	}
}
# Join this computer to the domain; this should cause a reboot.

# Note that we depend on the previous task to wait for the domain.



# Add this computer as a domain controller



Configuration ActiveDirectoryRoles
{
    import-dscResource -modulename PsDesiredStateConfiguration

    WindowsFeature ADDSInstall
    {
        Name= "AD-Domain-Services"
        Ensure='Present'
        IncludeAllSubFeature = $true
    }

    WindowsFeature RSATTools
    {
        Name= "RSAT-AD-Tools"
        Ensure='Present'
        IncludeAllSubFeature = $true
        DependsOn = "[WindowsFeature]ADDSInstall"
    }
    Service ADDS
    {
        Name = "ADWS"
        DependsOn = "[WindowsFeature]ADDSInstall", "[WindowsFeature]RSATTools"
        StartupType = 'Automatic'
        Ensure = "Present"
    }
}

Configuration ADDS {
    param 
    ( 
        [Parameter(Mandatory)] 
        [string]$NodeName
    )
    
    Node $NodeName
    {
		WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }            
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }    
	}
}
#>

$cd = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
            PSDscAllowDomainUser = $true
            PSDscAllowPlainTextPassword = $true
        }
    )
}
