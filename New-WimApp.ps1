[cmdletBinding()]
param(
    [Parameter(Mandatory=$true,HelpMessage='The path to save the .wim file.')]
    [ValidateScript({Test-Path -Path $_})]
    [string]$Destination,
    [Parameter(Mandatory=$true,HelpMessage='The path to the files that will be in the .wim file.')]
    [ValidateScript({Test-Path -Path $_})]
    [string]$Path,
    [Parameter(Mandatory=$true,HelpMessage='Name of the .wim file.')]
    [string]$Name,
    [Parameter(Mandatory = $false, HelpMessage = 'Path to Save Log Files')]
    [string]$LogPath = "$env:Windir\Logs"

)

begin{
    #-- BEGIN: Executes First. Executes once. Useful for setting up and initializing. Optional
    if($LogPath -match '\\$'){
        $LogPath = $LogPath.Substring(0,($LogPath.Length - 1))
    }
    Write-Verbose -Message "Creating log file at $LogPath."
    #-- Use Start-Transcript to create a .log file
    #-- If you use "Throw" you'll need to use "Stop-Transcript" before to stop the logging.
    #-- Major Benefit is that Start-Transcript also captures -Verbose and -Debug messages.
    $ScriptName = & { $myInvocation.ScriptName }
    $ScriptName =  (Split-Path -Path $ScriptName -Leaf)
    Start-Transcript -Path "$LogPath\$($ScriptName.Substring(0,($ScriptName.Length) -4)).log"
}
process{
    #-- PROCESS: Executes second. Executes multiple times based on how many objects are sent to the function through the pipeline. Optional.
    try{
        #-- Try the things
        Write-Verbose -Message "Verifying files are present in $Path."
        if(((Get-ChildItem -Path "$Path" -File) | Measure-Object).Count -lt 1){
            Throw "Directory is empty."
        }

        $wim = "$($Destination)\$($Name).wim"

        ###-- Create a while loop to test if a WIM already exists with that name
        ###-- If it does, rename the wim and try again
        $count = 0
        while(Test-Path -Path $wim){
            Write-Warning -Message "$wim already exists. Attempting to add a number to the name and try again."
            $count++
            $wim = "$($Destination)\$($Name)_$($count).wim"
        }

        Write-Verbose -Message "Creating $($Name).wim at $Destination."
        New-WindowsImage -ImagePath "$wim" -CapturePath "$Path" -CompressionType Max -Name "$Name" -Description "$Name in a WIM format."
        
    } catch {
        #-- Catch the error
	    Write-Error $_.Exception.Message
	    Write-Error $_.Exception.ItemName
    }
}
end{
    # END: Executes Once. Executes Last. Useful for all things after process, like cleaning up after script. Optional.
    Stop-Transcript
}