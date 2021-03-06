<#
    PROGRAM :   Windows Power-Shell Tester <WSH>

    Author  :   P.Hassen
    Date    :   Version:05.09.2019

    !REM-200419:transcription-interruption
        The streaming feature flushes the normal transcript-output into the
            STREAM-output-file.
        This causes nearly empty transcription log-files.
        Using the option '-Raw' avoids this beaviour.

    usage  :   PSH>  .\run.ps1 [ <tc> || <opt> ] [iStressCounter] [<switch>]
                <tc>        :=  <tcFile> || '.\'<tcFile>
                <tcFile>    := 'w??*.ps1'
                <opt>       := <Optc> || <Opts>
                <Optc>      := {'!','+','?:help','h:help','c:clear','r:erase','v','f','m'}
                <Opts>      := {'fOldest','fNewest,'fNow','fStd'}
                <switch>    : -Verbose := use: Trace/Info
                            : -Raw     := output directy to screen
                                        && write competely into each TC-logfile ! => !REM-200419
    example:
                PSH>  .\run.ps1 <tc> 2
                PSH>  .\run.ps1 <tc> 2 -VERBOSE
                PSH>  .\run.ps1 <tc> -RAW
                PSH>  .\run.ps1 ! 5
                PSH>  _runW + -Verbose -Raw

    streaming:
        URL: https://devblogs.microsoft.com/scripting/understanding-streams-redirection-and-write-host-in-powershell/
        Window STREAMs
            1:output/success
            2:error
            3:warning
            4:verbose
            5:Debug
            6:Progress
            7:Output

    content:
        :m: args        :   define script arguments
        :m: language    :   interpreter specifics
        :m: compile     :   only compile 1 TC
        :m: usage       :   help
        :m: IO helper   :   rm, mv
        :m: menu        :   menu and output functions
        :m: option h... :   clean,move
        :m: dir&file    :   createDir, makeFileName, fileEncoder
        :m: tc tools    :   runTime(),ecCheck
        :m: logfile     :   logFetch, logConcat
        :m+ define      :   body defines
        :m+ parameter   :   read and handle
        :m+ stress      :   parameter stress counter
        :m+ stream      :   prepare streaming - define files
        :m+ calling-mode:   tc called at PSH or via this script?
        :m+ eap:=true   :   Error Action Preference := stop
        :m+ run         :   run the test case
        :m+ eap:=false  :   Error Action Preference := <standard>
        :m+ finish      :   handle the results
#>


#
#   =*= :m: args
#

param(
    [string]    $Command    = '?',
    [int]       $Repeat     = 1,    # stress counter
    [switch]    $Raw,               # ?output directly to screen
    [switch]    $Verbose            # ?info-text and traces
)

# =*=   :m: include
#   already performed by the '$v_PROFILE_EXTENDED'

#   =*= :copy:: internal script args := external args
$p_arg_sCommand         = $Command  # <tc> || <opt>
$p_arg_iStressCounter   = $Repeat   # repeat command <n> times
$p_arg_bMode_raw        = $Raw      # TRUE => output to screen, noStreaming
$p_arg_bVerbose         = $Verbose  # TRUE => trace && info

#
#   =*= :m: language of the script
#

New-Variable C_cLanguageId       -option constant -value 'w'
New-Variable C_sExtensionId_src  -option constant -value 'ps1'

#
#   =*= :m: compile
#

function f_compile($p_sTc) {
    f__trace "tc:<$p_sTc>" (__LINE__)
    $fTc = ".\" + $p_sTc
    if ($p_arg_bMode_raw) {     # =:= mode:raw
        & $fTc
    } else {                    # =:= mode:stream
        & $fTc 2>&1 3>&1 4>&1 5>&1 6>&1 >>$v_sSTREAM_utf   # !REM-200419
    }
}

#   =*= :m: debug
$bDbg   = $false

#
#   =*= :m: usage
#

function f_usage() {
    puts "=h= help info" $v_COLOR_info
    $s = "`$> .\'$v_SCP' { <tc> || <option> } [<repeat>] [<switch>]"
    echo "$s"
    write-host @"
    <tc>        = { source file '$v_REX_src' }
    <option>    = <cOption> || <sOption>
    <cOption>   = {
                    '?','h' :help, * this text *
                    'v'     :show version
                    'c'     :clear at: <$v_DIR_tmp>
                    'r'     :erase at: <$v_DIR_log>,<$pwd> + clear
                    'f'     :fetch log at: <$v_DIR_tmp>
                    'm'     :move logs to <$v_DIR_log>
                    'n'     :concatenate logfiles
                    'y'     :f+n + copy to <$pwd>
                    '!'     :run all TC                     }
                    '+'     :shuffle <random(2,iTcMax/$C_iTcMax_divisor)> TC's  }
    <sOption>   = {
                    'fNew'  :fetch newest logfiles
                    'fOld'  :fetch oldest  ~
                    'fNow'  :fetch current ~
                    'fStd'  :perform fetch-automode         }
    <repeat>    = { [1,...$C_iMaxStress] := 1}
    <LogDirs>   = { STD='$v_DIR_tmp', ADD='$v_DIR_log', EXD='$v_DIR_out'
    <switch>    = { -raw     : ?output to screen := FALSE,
                    -verbose : ?info/trace := FALSE         }
"@
}


#
#   =*= :m: IO helper
#

function f__rm( $p_sRex = $NULL, $p_sDir = $env:tmp ) {
    pushd $p_sDir
    $aSrc   = (ls $p_sRex)
    $n      = $aSrc.length  # puts "sRex=$p_sRex"; puts "n=$n"
    if ($n -gt 0 ) {
        $i = 0
        foreach ($x in $aSrc) {
            $i+=1; $s = "ReMOVE:{$x}:[$i]"; # debug: puts $s
            try {
                if ($v_bInfo) { puts $s }
                rm $x
            }
            catch { if ($v_bInfo) { f__error $s } }
        }
    }
    popd
}

function f__rmDir($p_sSubDir) {
    $d = "$v_DIR_tmp\$p_sSubDir"
    try     {  rmdir $d -recurse -force }
    catch   {  if ($v_bInfo) { f__error $s (__LINE__) } }
}

function f__mv( $p_sRex, $p_sDirSrc, $p_sDirObj) {
    $bTrc = $true
    $aSrc = (ls $p_sDirSrc\$p_sRex)
    if ( $aSrc.length -gt 0 ) {
        $n = $aSrc.length
        $s = "MOVE($n):'$p_sRex' FROM:<$p_sDirSrc>:TO:<$p_sDirObj>"
        try {
            mv $aSrc $p_sDirObj -Force
            if ($bTrc) { f__puts  $s }
        } catch {
            if ($v_bInfo) { f__error $s (__LINE__) }
        }
    }
}

#
#   =*= :m: menu and output functions
#

function f__logs( $p_sText = '?no', $p_sFile = $v_sSTREAM_utf ) {
    write-output "$p_sText" >> $p_sFile
}

function f__puts(
            $p_sText,
            $p_sFile = $v_sSTREAM_utf,  # mode:stream
            $p_sColor = $v_COLOR_text,
            $p_cTab   = '<',
            [switch] $p_bCol,
            [switch] $p_bTab,
            [switch] $p_bLog,
            [switch] $p_bInf,  # only output, if info mode
            [switch] $p_bNoNL,
            $p_iLine = -1)
{
    $s  = "$p_sText"
    if ( $p_bTab ) { $sTab = $p_cTab * 3; $s = "$sTab $s" }
    if ( $p_iLine -gt 0 ) { $s += " at:[$p_iLine]" }
    $bOut = $true
    if ( $p_bInf ) {
        if (!$v_bInfo) { $bOut = $false }
    }
    if ($bOut) {
        if ( $p_bCol ) {
            if ( $p_bNoNL ) {
                    write-host "$s" -ForegroundColor $p_sColor -NoNewLine }
            else {  write-host "$s" -ForegroundColor $p_sColor }
        } else {
            if ( $p_bNoNL ) {
                    write-host "$s" -NoNewLine }
            else {  write-host "$s" }
        }
    }
    if ($p_bLog -and $bStreamingLogging) {  # check:FILE.utf
        write-output "$s" >> $p_sFile   # mode:stream
    }
}

function f__menu($p_sText, $p_iLine, $p_iRT = -1, [switch] $p_bChkEc) {
    $t = "'$p_sText'"; if ($p_iRT -gt 0) { $t += ":<$p_iRT s>" }
    $s = "SCP:{'$v_SCP'}:{'$v_DATE'}:{$g_iEc}:$t"
    $s = "=m= $s [$p_iLine]"
    if ($p_bChkEc) {
        if (f_bCheckEc $g_iEc) {
            $s += ":OK"
        } else {
            $s += ":FALSE"
        }
    }
    puts "$s" $v_COLOR_menu
    if ($bStreamingLogging) { f__logs $s }
}

function f__info($p_sText, $p_iLine = -1) {
    if ($v_bInfo -eq $true) {
        $s = "=i= $p_sText"
        if ($p_iLine -gt 0) {
            $s += " at:[$p_iLine]"
        }
        puts $s $v_COLOR_info
        if ($bStreamingLogging) { f__logs $s }
    }
}

function f__trace($p_sText, $p_iLine=-1) {
    if ($v_bTrace) {
        $Fn = (Get-PSCallStack)[1].FunctionName
        $s  = "=t= $p_sText"
        $s += " at:[$Fn"
        if ($p_iLine -gt 0) {
            $s += ";$p_iLine"
        }
        $s += "]"
        puts $s $v_COLOR_trace
        if ($bStreamingLogging) { f__logs $s }
    }
}

function f__error($p_sError, $p_iLine=-1) {
    $s = "??? <$p_sError>"
    if ($p_iLine -gt 0) {
        $s += " at:[$p_iLine]"
    }
    puts $s $v_COLOR_error
    if ($bStreamingLogging) { f__logs $s }
}

#
#   =*= :m: option handler
#

function f_version() {
    f__trace "show version..." (__LINE__)
    $x = $(Get-Item $v_SCP).lastWriteTime
    puts "VERSION1:=<$x>" 'magenta'
<#
    !URL:https://www.ghacks.net/2017/10/09/how-to-edit-timestamps-with-windows-powershell/
    The three commands that you require are the following ones:
    ◾   $(Get-Item FILENAME.EXT).creationtime=$(DATE)
    ◾   $(Get-Item FILENAME.EXT).lastaccesstime=$(DATE)
    ◾   $(Get-Item FILENAME.EXT).lastwritetime=$(DATE)
    use:
    PSH>   get-childitem -force |
        Select-Object Mode, Name, CreationTime,
                    LastAccessTime, LastWriteTime | ft
#>
}

function f_clean($p_sRex = $NULL) {
    f__trace "do cleaning..." (__LINE__)
    if ($p_sRex-eq $NULL) {
        f__trace "clean:NULL" (__LINE__)
        f__rm($C_cLanguageId + '??_*.'    + $C_sExtensionId_csv)
        f__rm($C_cLanguageId + '??_*.'    + $C_sExtensionId_out)
        f__rm($C_cLanguageId + '??_*.' + '????????????.' + $C_sExtensionId_log)
        f__rm($v_SID + '*.txt')
        f__rm($v_SID + '*.utf.'         + $C_sExtensionId_log)
        f__rm($v_SID + '*.asc.'         + $C_sExtensionId_log)
#       f__rm($v_SID + '.????????.'     + $C_sExtensionId_log)
    } else {
        f__trace "clean:<$p_sRex>" (__LINE__)
        f__rm($p_sRex)
    }
}

function f_erase() {
    f__info "do erase..." (__LINE__)
    f__rm($v_REX_log)($pwd.path)
    f__rm($v_SID + '*.' + $C_sExtensionId_log)
    f__rm("*.txt")
    f__rm("*.dat")
    f__rmDir('IOM')
    f__rmDir('IOM2')
    f__rmDir('log')
    f__rmDir('SVC')
}

function f_move() {
    $n=2
    f__puts "move logfiles to:'$v_DIR_log' in <$n> seconds ..."
    sleep($n)
    f__mv($v_REX_log)($pwd)($v_DIR_log)
    f__mv($v_REX_log)($env:tmp)($v_DIR_log)
}

#
#   =*= :m: dir&file
#

#   DES: creating a Directory or check it
function f_dirCreate( $p_sDir ) {
    #   remove DIR if exists
    if (test-path "$p_sDir") {
        f__info "!dirCr '$p_sDir' already exists" (__LINE__)
        return(__LINE__)
    }
    # !PHA avoid any echo - else no correct return code
    $xRc = (new-item -Path $p_sDir -ItemType Directory)
    if (test-path $p_sDir) {
        f__info "!dirCr '$p_sDir' created" (__LINE__)
        return(__LINE__)
    }
    f__error("?dirCr '$p_sDir' creation fails")(__LINE__)
    return(-(__LINE__))
}

#   DES: concat DIR and FILE - returns UNIX fileName
function f_sFileName($p_sDir,$p_sFnm) {
    $s      = $p_sDir + '/' + $p_sFnm
    $sRc    = $s.replace('\','/')    # DOS=>UNIX
    return $sRc
}

#   DES: reading a complete file and encoding into wanted format
function f_fileEncoder ($p_sFileSrc,$p_sFileObj,$p_sEncoding = 'ascii') {
    f__trace "encoder:<$p_sFileSrc>=> <$p_sFileObj> ($p_sEncoding)"(__LINE__)
    $x  = get-content $p_sFileSrc
    $c  = $p_sEncoding
    $x  | out-file $p_sFileObj -Encoding $c
}

#
#   =*= :m: tc tools
#

function f_iRuntime($p_bStart) {
    $dt = get-date      #    -format HH:mm:ss
    if ($p_bStart) {
        $script:v_runtime_start = $dt
        return 0
    } else {
        $tRuntime_stop  =   $dt
        $tRunTime       =   new-timespan $script:v_runtime_start $tRuntime_stop
        $iRunTime       =   $tRunTime.Seconds
        $iRunTime       +=  $tRunTime.Minutes * 60
        $iRunTime       +=  $tRunTime.Hours   * 60 * 60
        $iRunTime       +=  $tRunTime.Days    * 60 * 60 * 24
        return $iRunTime
    }
}

function f_bCheckEc($p_iEc = $g_iEc) {

    $bTest = $false

    #   test exit code
    if ($bTest) {
        $env:v_EXIT_CODE    = -(__LINE__)
        $LastExitCode       = -(__LINE__)
    }

    $sEcInfo = "(i|L)=($p_iEc|$LastExitCode)"
    $bRc     = $false

    if ($LastExitCode -eq $p_iEc) {
        $sTxt   = "Ec==gEc => $sEcInfo =>:!!:OK"
        $sCol   = 'DarkGreen'
        $bRc    = $true
    } elseif ($LastExitCode -eq 0) {
        $sTxt   = "Ec=:0 => $sEcInfo =>:!?:warning"
        $sCol   = 'Yellow'
        $bRc    = $true
    } elseif ($LastExitCode -eq 1) {
        $sTxt   = "Ec=:1 => $sEcInfo =>:??:standard error"
        $sCol   = 'DarkRed'
    } else {
        $sTxt   = "Ec =: $sEcInfo =>:??:NOK"
        $sCol   = 'Red'
    }

    #   show
    if ($p_arg_bMode_raw) {
        puts "$sTxt" $sCol
    } else {
        puts "`t:$sTxt" $sCol
    }

    return $bRc

} # f~chkEc

#
#   =*= :m: logfile functions
#

function f_logFetch($p_sLogRex = $v_REX_log,
                    $p_i64DateTime_min = 0,
                    $p_i64DateTime_max = 0,
                    [switch] $p_bNewest,
                    [switch] $p_bOldest,
                    [switch] $p_bAutomode )  # take defaults
{
    <#
        REM:    logFetch only reads files - it doesn't write on HDD
        use1:   fetch only files with dateTime in timeSpan [min;max]
        use2:   fetch only either -p_bNewest or -p_bOldest, when there
                are more than one files found
        REM:    else - take all files
        return: array of fetched logFiles
    #>
    #   more traces
    $bTrc       = $True
    $bDbg       = $False

    #   parameter
    if ($bTrc) {
        f__trace "sRex:{$p_sLogRex}" (__LINE__)
    }
    #   automode
    if ($p_bAutomode) {
        $p_sLogRex          = $v_REX_log
        $p_i64DateTime_min  = $iRunTimeTc_min
        $p_i64DateTime_max  = $iRunTimeTc_max
        $p_bNewest          = $true
    }

    if ($p_sLogRex.length -eq 0) {
        f__error "REX==0" __LINE__
        return 0
    }

    pushd $v_DIR_tmp

    #   get corresponing files
    $aDir       = get-childitem -path $p_sLogRex | sort-object LastAccessTime -Descending

    #   remove manually dirPath
    if ($bTrc) { f__trace "SID:{$v_SID}" (__LINE__) }
    $aFile   = @()
    foreach ($x in $aDir ) {
        $f = [io.path]::GetFileName($x)
        if ($f -Like "$v_SID*") {   #   !CRQ-200829:ignore SID files
            continue
        }
        $aFile += $f
        if ($bDbg) { f__trace "{$f} notlike {$v_SID}" (__LINE__) }
    }
    if ($bDbg) { f__trace "aFile1:{$aFile}" (__LINE__) }

    #   sort again
    $aFile  = $aFile | sort-object
    if ($bTrc) { f__trace "aFile2:{$aFile}" (__LINE__) }

    #   Seek files newer than p_i64DateTime
    #   returns: aLog

    $aLog           = @()   #   return array
    $iLog           = 0     #   number of saved log files

    $sHdr_last      = $NULL # TC name =: w01-intro,...
    $iPartsWanted   = 3     # filename, date, extension

    $i = 0                  #   number of files in 'aFilePathes'
    foreach ($x in $aFile) {

        $i += 1

        #   we are looking for 3 parts in:
        #       $x = "X:\TEMP\w01-intro.20190412170119.log"
        #   3 parts: 01='w01-intro' 02='190412170119' 03='log'

        $r = [io.path]::GetPathRoot($x)         # x:
        $d = [io.path]::GetDirectoryName($x)    # x:\temp
        $f = [io.path]::GetFileName($x)         # w01_intro.190412170119.log

        if ($bDbg) { f__trace "ROOT:{$r}" (__LINE__) }
        if ($bDbg) { f__trace "DIR:{$d}" (__LINE__) }
        if ($bDbg) { f__trace "LogFile:{$f}" (__LINE__) }

        #   split filename
        $c = '.'
        $a = $f.Split($c)
        $l = $a.length
        if ($bDbg) { f__trace "split.l:{$l}" (__LINE__) }

        #   check
        if ($l -ne $iPartsWanted) {
            continue
        } # if-continue

        #   fetch 3 parts
        $sHdr = $a[0]   # tc name
        $sBdy = $a[1]   # dateTime
        $sExt = $a[2]   # file extension

        #   check extension
        if ($sExt -ne $C_sExtensionId_log) {
            f__trace "??? sExt:($sExt) != ($C_sExtensionId_log)" __LINE__
            continue
        } # if-continue

        #   check integer string
        $bRc,$iRc = f_lib_s2i($sBdy)
        if (! $bRc) {
            f__trace ("?NoDateTimeString:BDY:=<$sBdy>") (__LINE__)
            continue
        } # if-continue

        if ($bDbg) { f__trace "sHdr:{$sHdr}" (__LINE__) }    # hdr:'w01_intro'
        if ($bDbg) { f__trace "sBdy:{$sBdy}" (__LINE__) }    # bdy:'190412170119'
        if ($bDbg) { f__trace "sExt:{$sExt}" (__LINE__) }    # ext:'log'

        #   fetch:01 condition:='files in timespan'
        if (($p_i64DateTime_min -gt 0) -and  ($p_i64DateTime_max -gt 0)) {
            #   check dateTime only : if (dtMin>0 && dtMax>0)
            $i64Dt = [int64][string]($sBdy)
            if ($i64Dt -lt $p_i64DateTime_min) {
                f__trace ("DT:($i64Dt) <  ($p_i64DateTime_min)") (__LINE__)
                continue
            }
            elseif ($i64Dt -gt $p_i64DateTime_max) {
                f__trace ("DT:($i64Dt) >  ($p_i64DateTime_max)") (__LINE__)
                continue
            }
        }

        #   fetch:02 condition:='the neweset of each TC'
        if ( $p_bNewest -or $p_bOldest) {
            if ($sHdr -ne $sHdr_last) {
                $iLog += 1
                $aLog += $f             # +++ : aRc+=f
                $sBdy_hit   = $sBdy     # dt.hit  := dt.current always
                $sHdr_last  = $sHdr     # tc.last := tc.current
                if($bTrc){f__trace "sHdr_last={$sHdr_last}"}
            }
            else {
                if (( $p_bNewest -and ($sBdy -gt $sBdy_hit) ) -or
                    ( $p_bOldest -and ($sBdy -lt $sBdy_hit)     ) )
                {
                    #   dt.hit := dt.current
                    $sBdy_hit       = $sBdy     # timeMax:=timeCurrent
                    $aLog[$iLog-1]  = $f      # overwrite name
                    if($bTrc){f__trace ("ov:$f") (__LINE__) }
                }
            } # if-else
        } else {
            $aLog += $f # +++ : aRc+=f
        }

    } # foreach

    f__trace "parses <$i> files" (__LINE__)

    popd

    return $aLog

} # f~logFetch

function f_logConcat ( $p_aLog_src,
        $p_sDir_obj  = $v_DIR_tmp,
        $p_sFile_obj = $NULL,
        $p_bCopy2Pwd = $false,      # copy (back) to PWD
        [switch] $p_bAutomode )
{
    <#
        IN:     array of files
        OUT:    object file
        REM:    all logfiles was created at tmpDir
        RET:    iNrOfFilesConcatenated,iSizeOfObjFile,sNameOfObjFile
    #>

    #   File Name ID
    $FID = [io.path]::GetFileNameWithoutExtension( $MyInvocation.MyCommand.Name )

    #   how many files to handle?
    $n = $p_aLog_src.length
    f__trace ("p_aLog_src($n):<$p_aLog_src>") (__LINE__)

    #   automode handles
    if ($p_bAutomode) {
        $p_sFile_obj = $NULL
        $p_sDir_obj  = $v_DIR_tmp
        $p_bCopy2Pwd = $true
    }

    #   use fix names for build or take input filename
    if ($p_sFile_obj -eq $NULL) {
        $sFName = $C_sLogfile_asc
    } else {
        $sFName = $p_sFile_obj
    }
    $f = f_sFileName $p_sDir_obj $sFName

    #   encoding
    $cEncoding  = 'ascii'

    #   main:header
    $s = ">>>:HD:{$FID}:{$sDate}"
    $s | out-file $f -Encoding $cEncoding  # create:header

    $i = 0
    puts "concatenate files"  -p_bCol -p_bTab   # !CRQ-200829

    pushd $v_DIR_tmp
    foreach ($xFile in $p_aLog_src) {
        $i ++
        $s = "---:by:{$FID}:TC:($i/$n):<$xFile>"; puts $s
        $s | out-file $f -Encoding $cEncoding -Append   # flush:body name
        $s = get-content $xFile
        $s | out-file $f -Encoding $cEncoding -Append
    }
    popd

    #   main:footer
    $s = "<<<:HD:{$FID}:{$sDate}"  # footer
    $s | out-file $f -Encoding $cEncoding -Append       # flush:footer

    #   file size
    $iSz = (get-item $f).length
    $sRc = "{$FID}: I have written file: '$f' (size:$iSz)"
    f__puts "$sRc" -p_bCol -p_bTab

    #   file Copy
    if ($p_bCopy2Pwd) {
        f_logCopy($f)
    }
    return $i, $iSz, $f

} # f~logConcatAndCopy

function f_logCopy($p_fSrc) {
        $fSrc  = $p_fSrc
        $fObj  = f_sFileName $v_DIR_out $C_sLogfile     # !CRQ-200828
        copy-item $fSrc $fObj
        f__puts "!copy.WSH...: <$fSrc> => <$fObj>"  -p_bCol -p_bTab

} # f~logCopy

#   ---------------------------------------------------------------------------
#   =*= :m+ define : BODY
#   ---------------------------------------------------------------------------

#   =*=:m:flags
$v_bTrace       = $true    # $true
$v_bInfo        = $true     # $true
$v_bTest        = $false

#   =*=:m:color and screen
cls
$v_COLOR_text='cyan'
$v_COLOR_menu='green'
$v_COLOR_trace='magenta'
$v_COLOR_info='yellow'
$v_COLOR_error='red'

#   =*=:m:SID
$v_SCP  = $MyInvocation.MyCommand.Name
$v_SID  = [io.path]::GetFileNameWithoutExtension( $v_SCP )
$v_DATE = get-date -format 'yyMMddHHmmss'
$T      = get-date -format 'ddHHmmss'

#   =*=:m:const definition
New-Variable C_iMaxStress       -Option constant    -Value 101
New-Variable C_sExtensionId_log -Option constant    -Value 'log'
New-Variable C_sExtensionId_csv -Option constant    -Value 'csv'
New-Variable C_sExtensionId_out -Option constant    -Value 'out.txt'
New-Variable C_sLogfile         -Option constant    -Value "$v_SID.ps1.log"
New-Variable C_sLogfile_utf     -Option constant    -Value "$v_SID.$T.utf.log"
New-Variable C_sLogfile_asc     -Option constant    -Value "$v_SID.$T.log"
New-Variable C_iTcMax_divisor   -Option constant    -Value 4

#   =*=: set exit code
$g_iEc =  Get-Random -Minimum 1001 -Maximum 9999 # script exit code
$env:v_EXIT_CODE = $g_iEc   # EC.env:=EC.scp : exitCode environment

#   =*=: matches and logId
$v_REX_src  =  $C_cLanguageId + '??_*.' + $C_sExtensionId_src  # source files
$v_REX_log  =  $C_cLanguageId + '??*.'  + $C_sExtensionId_log  # tc logfiles

#   =*=: stream ID for mode:stream
$v_RID      = "$v_SID." +  (Get-Date -Format 'HHmmss')

#   =*=: Dir :: the wsh-tutorial loggs to tmpDir and not to the PWD
$v_DIR_tmp   =  "$env:tmp"          # normal logDir
$v_DIR_log   =  "$env:tmp\log"      # additionally logDir - move logs before
$v_DIR_out   =  "d:\MY\log" # additionally logDir - compare to BSH

#   =*=: logCopy Id
$sLogCopyId  = "{$v_SCP}:{$v_DATE}:{$g_iEc}"

#   =*=: header
f__menu('header')(__LINE__)     # first function call

#   ---------------------------------------------------------------------------
#   =*= :m+ parameter
#   ---------------------------------------------------------------------------

#   =*= :flags
$v_bTrace = $false; $v_bInfo = $false;
if ( $p_arg_bVerbose ) {
    $v_bTrace   = $true
    $v_bInfo    = $true
}
$bCleanRisky   = $false
$bFetchRisky   = $true
$bStreamingLogging  = -not( $p_arg_bMode_raw )


f__info "p.vScp                 :=  <$p_arg_sCommand>" (__LINE__)
f__info "p.iStressCounter       :=  <$p_arg_iStressCounter>" (__LINE__)
f__info "p.bVerbose             :=  <$p_arg_bVerbose>" (__LINE__)
f__info "p.bRaw                 :=  <$p_arg_bMode_raw>" (__LINE__)

f__info "srcRex := $v_REX_src"
f__info "logRex := $v_REX_log"

#   =*= :logdir
#   !PHA: must be performed at this place, we need verbose flags
if ($v_bTest) {
    rmdir $v_DIR_log
}
$iRc = f_dirCreate($v_DIR_log)
if ($iRc -lt 0) {
    exit(__LINE__)
}

#   =*= :fetch possible TC
$aTcAll=@(); $aTc=@()
$x      =    gci $v_REX_src;
$aTcAll =   $x.Name
f__info("aTcAll:<$aTcAll>")(__LINE__)

#
#   =*= :handle p_arg_sFileTc
#

switch($p_arg_sCommand) {

    '?' { f_usage }
    'h' { f_usage }
    'v' { f__puts "... version" ; f_version }
    'c' { f__puts "... clean"   ; f_clean   }
    'r' { f__puts "... erase!"  ; f_erase   }
    'f' {       # fetch logfiles
        $aLog       = f_logFetch("$v_REX_log")
        $n          = $aLog.length
        f__puts "aLog.all($n):{$aLog}"
     }
    'fNew' {
        $aLog  = f_logFetch("$v_REX_log") -p_bNewest
        $n     = $aLog.length
        f__puts "aLog.new($n):{$aLog}"
    }
    'fOld' {
        $aLog   = f_logFetch("$v_REX_log") -p_bOldest
        $n      = $aLog.length
        f__puts "aLog.old($n):{$aLog}"
    }
    'fNow' {    #   show my current logfiles
        $aLog = f_logFetch `
            -p_sRex            = "$v_REX_log" `
            -p_i64DateTime_min = $iRunTimeTc_min `
            -p_i64DateTime_max = $iRunTimeTc_max `
            -p_bNewest
        $n  = $aLog.length
        f__puts "aLog.NOW($n):{$aLog}"
    }
    'fStd' {    #   use automode == now
        $aLog = f_logFetch -p_bAutomode
        $n    = $aLog.length
        f__puts "aLog.STD($n):{$aLog}"
    }
    'n' {       #   concat into 1 common logfile
        $aLog   = f_logFetch("$v_REX_log") # allTc
        $n      = $aLog.length
        f__trace "aLog.CON($n):{$aLog}" (__LINE__)
        $iRc,$iSz,$sRc = f_logConcat -p_aLog_src $aLog
        f__trace "RC.n:={$iRc}:{$iSz}:{$sRc}" (__LINE__)
    }
    'y' {       #  like 'n', but finally copy to "$PWD\SCP.log"
        $aLog   = f_logFetch("$v_REX_log") # allTc
        $iRc,$iSz,$fSrc = f_logConcat $aLog -p_bAutomode
        f__trace "RC.y:={$iRc}:{$iSz}:{$sRc}" (__LINE__)
    }
    'm' {       #   move to logDir
        f_move
    }
    '!' {       #  run all-Tc
        f__trace("option:='!'")(__LINE__)
        $n = $aTcAll.length
        if ( $n -eq 0 ) { f__error ("NoTcFound")(__LINE__); exit(-(__LINE__)) }
        $aTc = $aTcAll
        if ($bCleanRisky) {
            f_clean # !CRQ-200828:risky
        }
        f__trace("option:='use all TCs'")(__LINE__)
    }
    '+' {       #  run med-Tc
        $n = $aTcAll.length
        f__trace("option:='+' of <$n>")(__LINE__)
        if ( $n -eq 0 ) { f__error ("NoTcFound")(__LINE__); exit(-(__LINE__)) }
        $aTcTmp = $aTcAll | sort { Get-Random }
        $aTc=@()
        $m = $n = $aTcAll.length / $C_iTcMax_divisor
        $m -= 1
        $m  = f_lib_random($m)  # m = 1...n-1
        $m += 1                 # m = 2...n
        for ($i=0; $i -lt $m; $i++) {
            $aTc += $aTcTmp[$i]
        }
        if ($bCleanRisky) {
            f_clean # !CRQ-200828:risky
        }
        f__puts "shuffle.aTc<$m>:{$aTc}"
    }
    default {   #   run single-Tc or wrong option

        #   01:test a valid file
        if (!(test-path $p_arg_sCommand)) {
            f__error ("unknown option '$p_arg_sCommand'")(__LINE__)
            exit(-(__LINE__))
        }

        #   <tc> := command

        #   02:remove auto-complete fileName  ".\<filenames>
        $m  = '.\'  # auto-complete string
        $s  = [system.String]::join('', $p_arg_sCommand[0..1])
        f__trace("compare:<$s> and <$m>")(__LINE__)
        if ($s -eq $m) {
            f__trace("remove filename begin:<$m>")(__LINE__)
            $sTc  = $p_arg_sCommand.SubString(2);
        } else {
            $sTc =  $p_arg_sCommand
        }
        f__trace("useTc:<$sTc>")(__LINE__)

        #   03:find tc in tcAll
        if (!($aTcAll -contains $sTc)) {
            f__error ("unknown Script:'$p_arg_sCommand'")(__LINE__)
            exit(-(__LINE__))
        }
        f__trace("Tc:<$sTc> found in aTc")(__LINE__)

        #   04:define aTc
        $aTc =  @()
        $aTc += $sTc

        #   05:clean - !CRQ-200828:risky
        if ($bCleanRisky) {
            $sRex = [system.String]::join('', $sTc[0..2])
            $sRex += '*.log'
            f__trace("tryClean:<$sRex> of:<$sTc>")(__LINE__)
            f_clean($sRex)
        }

    } # default

} # switch command:<opt>||<tc>  #   TEST<opt>: ; return __LINE__

#   =*= : LEAVE with single options '?' or 'c'
$n = $aTc.length
if ($n -eq 0) {
    f__menu('footer')(__LINE__)
    exit(-(__LINE__))
}
f__trace "aTcUse($n):{$aTc}" (__LINE__)

#   :m+ stress : set max counter
if ($p_arg_iStressCounter -gt $C_iMaxStress) {
    $p_arg_iStressCounter = $C_iMaxStress
    f__trace("use: iStress:=<$p_arg_iStressCounter>")(__LINE__)
}

#   :m+ stream logging prepare
if ($bStreamingLogging) {   # mode:stream
    $v_sSTREAM_utf  =   $env:tmp + '\' + $C_sLogfile_utf
    $v_sSTREAM_asc  =   $env:tmp + '\' + $C_sLogfile_asc
    f__trace("v_sSTREAM_utf:=<$v_sSTREAM_utf>")(__LINE__)
    f__trace("v_sSTREAM_asc:=<$v_sSTREAM_asc>")(__LINE__)
} # if StreamingLogging

#   :m+ calling-mode for TC
#   ? Is the TC
#       a) directly via PSH or
#       b) called by this script
$env:v_bModeBatch = $true   # informs the TC whether BATCH or

#   :m+ eap:=true
$v_ErrorActionPreference = $ErrorActionPreference   # save
$ErrorActionPreference = 'stop' # stop's immediately hard errors

#   ---------------------------------------------------------------------------
#   =*= :m+ run the TC
#   ---------------------------------------------------------------------------

#   logging: RUNTIME.start
$iRunTime           =   f_iRuntime($true)
f__puts "--- START:<$sLogCopyId>" -p_bLog -p_bInf; sleep(1)

#   save and prepare formtted output strings
$nRun   = $p_arg_iStressCounter;    $nRun_s = "{0:d2}"-f $nRun
$nTc    = $aTc.length;              $nTc_s  = "{0:d2}"-f $nTc

#   the BlackList saves failed TestCases
$aBlackTc = @()
$iEc = 0

for ( $iRun = 1; $iRun -le $nRun; $iRun ++ ) {

    # logging : >>> stressCounter[<current>/<max>]:iRunTimeTc_min
    $iRunTimeTc_min = [int64]([string](get-date -format yyMMddHHmmss))
    $iRun_s     = "{0:d2}"-f $iRun
    $sRun       = "[$iRun_s/$nRun_s] {$iRunTimeTc_min}"
    f__puts ">>> RUN: $sRun ..." -p_bLog -p_bInf ; sleep(1)

    $iTc = 0
    foreach ($xTc in $aTc) {

        $iTc ++         # 1..n

        #   already failed TC ?
        if ( $aBlackTc -contains $xTc) {
            f__puts "TcBlackList contains <'$xTc'>" `
                -p_bLog -p_bTab -p_bCol -p_sColor 'yellow'
            continue;
        } # if BlackList

        #   show+log : runTc[<current>/<max>]
        $iTc_s  = [String]::Format("{0:d2}", $iTc);
        $s = "runTc : [$iTc_s/$nTc_s] : [$iRun_s/$nRun_s] : '$xTc' "
        if ($p_arg_bMode_raw) { puts $s }
        else {
            f__puts $s -p_bLog -p_bNoNL
        }
        try {
            $iEc = $g_iEc
            f_compile($xTc)         #   +++ COMPILING +++
        }
        catch {
            $sEc = $Error[0]
            $iEc = -(__LINE__)
        }
        finally {
            #   puts "error:$bEc"
        }
        #   check the error code
        if (!(f_bCheckEc( $iEc ))) {
            if ($bDbg) { f__error("?Tc:={$iTc}")(__LINE__) }
            $aBlackTc += $xTc   # add to blackList
        } # if checkEc

    } #     foreach TC

    # logging : <<< stressCounter[<current>/<max>]:iRunTimeTc_max
    $iRunTimeTc_max = [int64]([string](get-date -format yyMMddHHmmss))
    $sRun           = "[$iRun_s/$nRun_s] {$iRunTimeTc_max}"
    f__puts "<<< RUN: $sRun ..." -p_bLog -p_bInf ; sleep(1)

    # show : current logfiles
    if ($bFetchRisky) {
        $aLog = f_logFetch -p_bAutomode
        $n  = $aLog.length
        f__trace "aLog($n):{$aLog}" (__LINE__)
    }
} # for iRun

#   logging: RUNTIME.stop
$iRunTime = f_iRuntime($false)
f__puts "--- STOP!:<$sLogCopyId>:iRT:={$iRunTime}" -p_bLog -p_bInf; sleep(1)

#   ---------------------------------------------------------------------------
#   =*= :m+ finish
#   ---------------------------------------------------------------------------

#
#   =*= :encoding
#

#   the stream file contains the TC output and
#   the logged Output of : f~~puts

#
#   =*= :target logfile
#
if ($p_arg_bMode_raw) {      # =:= mode:raw

    f__trace "mode:RAW" (__LINE__)

    #   v01: fetch
    $aLog = f_logFetch("$v_REX_log")
    f__trace("vb.aLog($n):{$aLog}")(__LINE__)

    #   v02: concat
    $iNumTc,$iSize,$sFname = f_logConcat $aLog -p_bAutomode
    f__trace "logConcat.Rc:={$iNumTc}:{$iSize}:{$sFname}" (__LINE__)
}
else {                      # =:= mode:stream

    f__trace "mode:STREAMING" (__LINE__)

    #   s01: encoding
    f_fileEncoder $v_sSTREAM_utf $v_sSTREAM_asc     # IN:utf OUT:asc
    f__trace ("encoded : {$v_sSTREAM_asc}")(__LINE__)

    #   s02: copy to TMP
    f_logCopy($v_sSTREAM_asc)


}

#   =*= :footer
f__menu('footer')(__LINE__)($iRunTime) #    -p_bChkEc

#   =*= :remove UTF !CRQ-200828
if (! $p_arg_bMode_raw) {      # =:= mode:raw
    rm $v_sSTREAM_utf       # !CRQ-200829:only!Raw
}

#   :m+ eap:=false
$ErrorActionPreference = $v_ErrorActionPreference

exit(__LINE__)