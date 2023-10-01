using namespace System.IO

# NOTE: The extensive commenting is to explain to my non-tech-savvy friend
#       what each part does when he goes through it (fear of malware :|)

<#
    .SYNOPSIS
    Partitions a file into multiple smaller files.
    .DESCRIPTION
    Partitions a file into multiple smaller files of at most $BlockSize size
    into a folder that has the name of the file without the extension and
    " - part" appended to it. The location of the said folder is the directory
    of the file that will be partitioned.
    .INPUTS
    NONE
    .OUTPUTS
    The directories/folders where the file parts are outputed.
#>
function Partition-File {
    param(
        [Parameter(Position=0, mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        # Information of the file that will be partitioned.
        [IO.FileInfo]$FileInfo,
        [Parameter(mandatory=$true)]
        # Size of the output blocks
        [int]$BlockSize = 1024 * 64
    )

    # Path of the output folder
    $basePath = "$($FileInfo.Directory.FullName)\$($FileInfo.BaseName) - parts"
    # Creates the output folder
    New-Item -Path $basePath -ItemType Directory
    # Open the file that will be partitioned for reading
    $fileStream = $FileInfo.OpenRead()
    # Make an object that reads binary data from the file
    $reader = New-Object IO.BinaryReader $fileStream
    # The buffer where the binary data that will be read will be stored
    $buffer = New-Object byte[] $BlockSize
    # The index of the partition
    $i = 0
    # If the last partition is of size < $BlockSize, if we write $BlockSize
    # bytes from the buffer into the partition file, there will be
    # $BlockSize - size number of bytes of garbage data at the end of the file
    $bytesRead = 0
    # While we haven't reached the end of the file
    while ($fileStream.Position -lt $FileInfo.Length) {
        $outFilePath = "$basePath\$i$($FileInfo.Extension).part"
        # We open the partition file for reading
        $outFile = [IO.File]::OpenWrite($outFilePath)
        # We write into the buffer and store the number of bytes read into
        # $bytesRead
        $bytesRead = $fileStream.Read($buffer, 0, $BlockSize)
        # We write the data we read into the partition file
        $outFile.Write($buffer, 0, $bytesRead)
        # Close the partition file, we are finished with it
        $outFile.Close()
        # Increment index
        $i++
    }
    # Close the main file, we have finished reading
    $fileStream.Close()
}

<#
    .SYNOPSIS
    Partitions every file from a list into multiple smaller files.
    .DESCRIPTION
    Loops through $FileInfos and calls Partition-File with each item as
    -FileInfo and $BlockSize as -BlockSize.
    .INPUTS
    NONE
    .OUTPUTS
    NONE
#>
function Partition-Files {
    param(
        [Parameter(Position=0, mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        # The list of file infos
        [IO.FileInfo[]]$FileInfos,
        # Size of the output blocks
        [int]$BlockSize = 1024 * 64
    )
    # Loop through the list of files
    foreach ($fileInfo in $FileInfos) {
        # The Directory field of a file info is $null if it *is* a directory
        # aka. skip directories
        if ($fileInfo.Directory -ne $null) {
            Partition-File -FileInfo $fileInfo -BlockSize $BlockSize
        }
    }
}
