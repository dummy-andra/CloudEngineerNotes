$ThisDay = [datetime]::Today
$rootSourcePath = 'C:\Users\andra\Desktop\Projects\test'
$rootDestinationPath = 'C:\Users\andra\Desktop\work\sync-test'
$SourceDirectory = @()


$sourceDirectoryInfo = Get-ChildItem "$rootSourcePath" | Measure-Object
$sourceDirectoryInfo.count #Returns the count of all of the objects in the directory


# initialize the items variable with the
# contents of a directory

$items = Get-ChildItem -Path "$rootSourcePath"

if ($sourceDirectoryInfo.count -ne 0)
{
    # save directory name in an array
    foreach ($item in $items)
    {
        # if the item is a directory, then process it.
        if ($item.Attributes -eq "Directory")
        {
                Write-Host $item.Name #displaying

                $SourceDirectory += $item.Name  #storing in array

        }
    }
}



foreach ($name in $SourceDirectory)
{

    Get-ChildItem "$rootSourcePath\$name\logs" | 
    ForEach-Object{
        if($_.Length -eq 0 -and $_.CreationTime.Date -eq $ThisDay){  # What about non-zero length files?
            #$TodaysFiles += $_
            Select LastWriteTime, Name > "$rootDestinationPath\LastWriteTime.txt"
            Copy-Item -Path $rootSourcePath\$name\logs\$_  -Destination $rootDestinationPath\$name\$_
        }
    } 
    
    
    Get-ChildItem "$rootSourcePath\$name\logs\Archive" | 
    ForEach-Object{
        if( $_.CreationTime.Date -eq $ThisDay){  # What about non-zero length files?
            #$TodaysFiles += $_
            #Write-Host $_ #displaying
            Select LastWriteTime, Name > "$rootDestinationPath\LastWriteTimeArchive.txt"
            Copy-Item -Path $rootSourcePath\$name\logs\Archive\$_ -Destination $rootDestinationPath\$name\Archive\$_
        }
    } 
}