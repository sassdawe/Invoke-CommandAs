function Invoke-WmiCommandAs {

    #Requires -Version 3.0

    <#
    
    .SYNOPSIS
    
        Invoke Command as System/User on Local/Remote computer using ScheduleTask.
    
    .DESCRIPTION
    
        Invoke Command as System/User on Local/Remote computer using ScheduleTask.
        ScheduledJob will be executed with current user credentials if no -As <credential> or -AsSystem is provided.
    
        Using ScheduledJob as they are ran in the background and the output can be retreived by any other process.
        Using ScheduledTask to Run the ScheduledJob, since you can allow Tasks to run as System or provide any credentials.
        
        Because the ScheduledJob is executed by the Task Scheduler, it is invoked locally as a seperate process and not from within the current Powershell Session.
        Resolving the Double Hop limitations by Powershell Remote Sessions. 
    
        By Marc R Kellerman (@mkellerman)
    
    .PARAMETER AsSystem
    
        ScheduledJob will be executed using 'NT AUTHORITY\SYSTEM'. 
    
    .PARAMETER AsInteractive
    
        ScheduledJob will be executed using another users Interactive session. 
    
    .PARAMETER AsGMSA
    
        ScheduledJob will be executed as the specified GMSA. For Example, 'domain\gmsa$'
            
    .PARAMETER AsUser
    
        ScheduledJob will be executed using this user. Specifies a user account that has permission to perform this action. The default is the current user.
            
        Type a user name, such as User01 or Domain01\User01. Or, enter a PSCredential object, such as one generated by the Get-Credential cmdlet. If you type a user name, this cmdlet prompts you for a password.
            
    #>
    
        #Requires -Version 3

        #Parameters generated using ProxyCommand on v5.1
        #[System.Management.Automation.ProxyCommand]::Create((gcm Invoke-Command))

        [CmdletBinding(DefaultParameterSetName='class', SupportsShouldProcess=$true, ConfirmImpact='Medium', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113346', RemotingCapability='OwnedByCommand')]
        param(

            [Parameter(ParameterSetName='class', Mandatory=$true, Position=1)]
            [Alias('Command')]
            [ValidateNotNull()]
            [scriptblock]
            ${ScriptBlock},
        
            [Parameter(ParameterSetName='path', Mandatory=$true, Position=1)]
            [Alias('PSPath')]
            [ValidateNotNull()]
            [string]
            ${FilePath},
        
            [Alias('Args')]
            [System.Object[]]
            ${ArgumentList},
        
            [switch]
            ${AsJob},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [System.Management.ImpersonationLevel]
            ${Impersonation},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [System.Management.AuthenticationLevel]
            ${Authentication},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [string]
            ${Locale},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [switch]
            ${EnableAllPrivileges},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [string]
            ${Authority},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${Credential},
        
            [int]
            ${ThrottleLimit},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [Alias('Cn')]
            [ValidateNotNullOrEmpty()]
            [string[]]
            ${ComputerName},
        
            [Parameter(ParameterSetName='path')]
            [Parameter(ParameterSetName='class')]
            [Parameter(ParameterSetName='WQLQuery')]
            [Parameter(ParameterSetName='query')]
            [Parameter(ParameterSetName='list')]
            [Alias('NS')]
            [string]
            ${Namespace},

            [Parameter(Mandatory = $false)]
            [Alias("System")]
            [switch]
            ${AsSystem},
    
            [Parameter(Mandatory = $false)]
            [Alias("Interactive")]
            [string]
            ${AsInteractive},
    
            [Parameter(Mandatory = $false)]
            [Alias("GMSA")]
            [string]
            ${AsGMSA},
        
            [Parameter(Mandatory = $false)]
            [Alias("User")]
            [pscredential]
            [System.Management.Automation.CredentialAttribute()]
            ${AsUser}
        
        )
    
       Process {

            # Collect all the parameters, and prepare them to be splatted to the Invoke-Command
            [hashtable]$WmiMethodParameters = $PSBoundParameters
            $ParameterNames = @('AsSystem', 'AsInteractive', 'AsUser', 'AsGMSA', 'FilePath', 'ScriptBlock', 'ArgumentList')
            ForEach ($ParameterName in $ParameterNames) {
                $WmiMethodParameters.Remove($ParameterName)
            }
            
            If ($FilePath) { 
                $ScriptContent = Get-Content -Path $FilePath 
                $ScriptBlock = [ScriptBlock]::Create($ScriptContent)
            }
            
$ScriptBlock = [ScriptBlock]::Create(@"

If (`$PSVersionTable.PSVersion.Major -lt 3) {

    `$ErrorMsg = "The function 'Invoke-ScheduledTask' cannot be run because it contained a '#requires' " + `
                "statement for PowerShell 3.0. The version of PowerShell that is required by the " + `
                "module does not match the remotly running version of PowerShell `$(`$PSVersionTable.PSVersion.ToString())."
    Throw `$ErrorMsg
    Return 

}

$(${Function:Invoke-ScheduledTask}.Ast.Extent.Text)


`$ScriptBlock = {
    $($ScriptBlock.ToString())
}

`$ArgumentList = @"
    $($ArgumentList | ConvertTo-Json -Depth 5 -Compress)
"`@

`$Parameters = @{}
`$Parameters['ScriptBlock'] = `$ScriptBlock
If (`$ArgumentList) { `$Parameters['ArgumentList'] = `${ArgumentList} | ConvertFrom-Json }

$(If ($AsUser)        { "`$Parameters['AsUser'] = New-Object System.Management.Automation.PSCredential ('$($AsUser.GetNetworkCredential().UserName)', (ConvertTo-SecureString '$($AsUser.GetNetworkCredential().Password)' -AsPlainText -Force))" })
$(If ($AsSystem)      { "`$Parameters['AsSystem'] = ${AsSystem}" })
$(If ($AsInteractive) { "`$Parameters['AsInteractive'] = '${AsInteractive}'" })
$(If ($AsGMSA)        { "`$Parameters['AsGMSA'] = '${AsGMSA}'" })

Invoke-ScheduledTask @Parameters 
            
"@)
            
            $EncodedCommand = ConvertTo-EncodedCommand -ScriptBlock $ScriptBlock -NoProfile -NonInteractive
            
            Invoke-WmiMethod @WmiMethodParameters -Class 'Win32_Process' -Name 'Create' -ArgumentList $EncodedCommand

        }
        
    }
    