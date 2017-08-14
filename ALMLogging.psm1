function Write-ALMLog {
    <#
        .SYNOPSIS
        Writes log messages to the PowerShell session or CSV log file
      
        .DESCRIPTION
        The Write-ALMLog cmdlet writes log messages to the PowerShell session via any of the streams as well as also writing to a CSV log file if the 'LogPath' parameter is specified.

        One or more tags can be assocaited with each log message by passing an array of strings to the 'Tags' paramter.  Note that tags are not displayed as text in console output and are only included in the information stream as well as the CSV log file.
      
        Each log message has a defined severity of 'Milestone', 'Information' (default), 'Verbose', 'Warning' and 'Critical'.  This value is displayed in console output regardless of the stream and the CSV log file but is associated with the output object in the information stream.

        Pass a file path to the 'LogPath' parameter  to output a CSV log file.  If the file already exists it will be appended.

        .EXAMPLE
        The following writes a log message to the console of "Example message" via the information stream
    
        Write-ALMLog -Message "Example message"
      
        .EXAMPLE
        The following writes a log message to the console of "Example message" with 3 tags (called Tag1, Tag2 and Tag3) associated with it via the information stream

        Write-ALMLog -Message "Example message" -Tags @("Tag1","Tag2","Tag3")
      
        .EXAMPLE
        The following writes a log message to the console of "Example message" via the information stream and also creates or appends ExampleLog.csv in the current users TEMP directory
    
        Write-ALMLog -Message "Example message" -LogPath "$env:TEMP\ExampleLog.csv"
      
        .EXAMPLE
        The following writes a log message to the console of "Example message" with a severity of 'Critical' assocaited with it via the error stream and also creates or appends ExampleLog.csv in the current users TEMP directory
    
        Write-ALMLog -Message "Example message" -Severity "Critical" -OutputStream "Error" -LogPath "$env:TEMP\ExampleLog.csv"
      
        .PARAMETER Message
        THe mssage associated with the log entry
      
        .PARAMETER Tags
        An array of strings that are associated with the log entry in the CSV log file and the information output stream

        .PARAMETER Severity
        The severity can be specified as 'Milestone', 'Information' (default), 'Verbose', 'Warning', 'Critical' and 'Debug'.  This value is displayed in console output regardless of the stream and the CSV log file but is associated with the output object in the information stream.
      
        .PARAMETER OutputStream
        THe 'OutputStream' selects the PowerShell output stream to use.  The default is 'Information and the options are:
            - Output
            - Information
            - Verbose
            - Warning
            - Error
            - Debug

        .PARAMETER BackgroundColour
        The 'BackgroundColour' defines the backfround colour when using the host stream.The options are:
            - Black
            - DarkBlue
            - DarkGreen
            - DarkCyan
            - Yellow
            - DarkMagenta
            - DarkYellow
            - Gray
            - DarkGray
            - Blue
            - Green
            - Cyan
            - Red
            - Magenta
            - Yellow
            - White
        
        .PARAMETER ForegroundColour
        The 'ForegroundColour' defines the backfround colour when using the host stream.The options are:
            - Black
            - DarkBlue
            - DarkGreen
            - DarkCyan
            - Yellow
            - DarkMagenta
            - DarkYellow
            - Gray
            - DarkGray
            - Blue
            - Green
            - Cyan
            - Red
            - Magenta
            - Yellow
            - White
        
        .PARAMETER LogDateTimeString
        The sting to be interpreted by 'Get-Date -Format $DateTimeString' to format the date and time in the console output

        .PARAMETER LogPath
        If 'LogPath' is specified then a CSV file at the location specified will be created (or appended if it already exists) with the log event.

        .OUTPUTS
        <String[]> via whichever output stream is specified.
        <CsvFile> if 'LogPath' was specified
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory,ValueFromPipeline)]
        [string]$Message,

        [Parameter(Position=1,ValueFromPipeline)]
        [string[]]$Tags,

        [Parameter(Position=2,ValueFromPipeline)]
        [ValidateSet("Milestone","Information","Verbose","Warning","Critical","Debug")]
        [string]$Severity = "Information",

        [Parameter(Position=3,ValueFromPipeline)]
        [ValidateSet("Output","Information","Verbose","Warning","Error","Debug","Host")]
        [string]$OutputStream = "Information",

        [Parameter(Position=4,ValueFromPipeline)]
        [ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","Yellow","DarkMagenta","DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]
        [string]$BackgroundColour,

        [Parameter(Position=5,ValueFromPipeline)]
        [ValidateSet("Black","DarkBlue","DarkGreen","DarkCyan","Yellow","DarkMagenta","DarkYellow","Gray","DarkGray","Blue","Green","Cyan","Red","Magenta","Yellow","White")]
        [string]$ForegroundColour,

        [Parameter(Position=6,ValueFromPipeline)]
        [string]$LogDateTimeString = 'yyyyMMdd_hh:mm:ss',

        [Parameter(Position=7,ValueFromPipeline)]
        [string]$LogPath
    )

    BEGIN {} #BEGIN
    
    PROCESS {
        $MessagePrefix = "[$(Get-Date -Format $DateTimeString)][$($($MyInvocation.MyCommand))]"
        
        # Writing parameter values to debug stream
        Write-Debug "$MessagePrefix Starting $($MyInvocation.MyCommand)..."
        Write-Debug "$MessagePrefix Input parameters :"
        #$PSBoundParameters
        $i = 0
        do  {
            write-Debug "$MessagePrefix  - $($PSBoundParameters.Keys | Select-Object -Index $i) :  $($PSBoundParameters.Values | Select-Object -Index $i)"
            $i++
        } until ($i -gt $PSBoundParameters.count - 1)

        #region Output preference
        if ($LogPath) {
            Write-Debug "$MessagePrefix * LogPath means logging will be outputted to the PowerShell console and to CSV"
        } else {
            Write-Debug "$MessagePrefix * No 'LogPath' means logging will be ouputted to the PowerShell console only"
        }
        #endregion Output preference

        #region PSHost output
        Write-Debug "$MessagePrefix Generating PowerShell console output"
        $callStack = Get-PSCallStack
        #$PsHostLogData = "[$(Get-Date -Format $DateTimeString)]$(if ($Severity){"[$Severity]"})$(if ($callStack.Count -gt 1) {"[$(($callStack[1].FunctionName).replace('<Process>',''))]"}) $Message"
        $CallstackString = $callStack.FunctionName.replace('<Process>','').replace('<ScriptBlock>','').replace('Write-ALMLog','')
        $CallstackString = $CallstackString[$CallstackString.count..0] -join ‘|‘
        $PsHostLogData = "[$(Get-Date -Format $DateTimeString)]$(if ($Severity){"[$Severity]"})$(if ($callStack.Count -gt 1) {"[$CallstackString]"}) $Message"
        Write-Debug "$MessagePrefix PowerShell consle output :  $PsHostLogData"
        
        # determining which woutput stream to use
        switch ($OutputStream) {
            "Output" {
                Write-Output $PsHostLogData
            } #Output/switch ($OutputStream)

            "Information" {
                if ($Tags) {
                    Write-Information $PsHostLogData -Tags $Tags
                } else {
                    Write-Information $PsHostLogData
                }
            } #Information/switch ($OutputStream)

            "Verbose" {
                Write-Verbose $PsHostLogData
            } #Verbose/switch ($OutputStream)
            
            "Warning" {
                Write-Warning $PsHostLogData
            } #Warning/switch ($OutputStream)
            
            "Error" {
                Write-Error $PsHostLogData
            } #Error/switch ($OutputStream)

            "Debug" {
                Write-Debug $PsHostLogData
            } #Error/switch ($OutputStream)

           "Host" {
                if ($BackgroundColour -and $ForegroundColour) {
                    Write-Host -Object $PsHostLogData -BackgroundColor $BackgroundColour -ForegroundColor $ForegroundColour
                } elseif ($BackgroundColour) {
                    Write-Host -Object $PsHostLogData -BackgroundColor $BackgroundColour
                } elseif ($ForegroundColour) {
                    Write-Host -Object $PsHostLogData -ForegroundColor $ForegroundColour
                } else {
                    Write-Host -Object $PsHostLogData
                }
            } #Host/switch ($OutputStream)
        
        } #switch ($OutputStream)
        #endregion PSHost output

        #region CSV output
        if ($LogPath) {
            Write-Debug "$MessagePrefix Generating CSV file output"
            $CsvLogData = [pscustomobject]@{
                Date = Get-Date 
                User = "$env:userdomain\$env:USERNAME"
                Message = "$Message"
                Tags = "$(if ($Tags) {"{$($Tags -join '},{')}"})"
                Severity = "$Severity"
                OutputStream = "$OutputStream"
                Script = $MyInvocation.ScriptName
                Line = $MyInvocation.ScriptLineNumber
                Function = "$CallstackString"
            }
            
            Write-Debug "$MessagePrefix CSV output data :  "
            Write-Debug "$MessagePrefix Date :  $($CsvLogData.Date)"
            Write-Debug "$MessagePrefix User :  $($CsvLogData.User)"
            Write-Debug "$MessagePrefix Message :  $($CsvLogData.Message)"
            Write-Debug "$MessagePrefix Tags :  $($CsvLogData.Tags)"
            Write-Debug "$MessagePrefix Severity :  $($CsvLogData.Severity)"
            Write-Debug "$MessagePrefix OutputStream :  $($CsvLogData.OutputStream)"
            Write-Debug "$MessagePrefix Script :  $($CsvLogData.Script)"
            Write-Debug "$MessagePrefix Line :  $($CsvLogData.Line)"
            
            Write-Verbose "$MessagePrefix Appending CsvLogData to $LogPath"
            try {
                $CsvLogData | Export-CSV -Path $LogPath -Encoding ASCII -Append -NoTypeInformation -force
                Write-Debug "$MessagePrefix Appended $LogPath successfully"
            } catch {
                Write-Debug "$MessagePrefix Appending $LogPath failed"
                Write-Warning $Error[0].Exception.Message -WarningAction Continue
            }
        }
        #endregion CSV output

    } #PROCESS

    END {
        Write-Debug "$MessagePrefix Ending $($MyInvocation.MyCommand)"
    } #END
}




