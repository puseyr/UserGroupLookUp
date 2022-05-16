<# User Group Look up and .csv clean up script by Ron Pusey
    Deployed: 9/29/2021
    Version: 2.00.00
#>
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
$ExecutionContext.SessionState.LanguageMode = "FullLanguage"

$UserCredential = Get-Credential #Get users Credentials to validate against domain.
$saveLocation ='\\usnycsrv2uwfp1\upf\puseyr\WF\RF\Documents\01-VM\PowerShell building\UserGroupLookUp V2' #Save location Variable. Change this to save to your location of choice.
$csvFile = "UserCompare - $(get-date -f MMM-dd-yyyy_@hh-mm-ss).csv" #CSVFile Naming convention for Month / Day / Year @ Hour:Minute:Seconds


#While loop to keep the script running. While $Restart does not = n the script will keep running
while ($restart -ne 'n')
    {
        #Script pauses and prompts the user to choose one of three options. Look up one users group, Look up two users and compare their groups, clean out .csv files from piling up
        $choice = Read-Host "`n`nChoose the following options 
                             `n1. User Group Look up for Single user 
                             `n2. User Group Look Up For Two + Compare  
                             `n3. Clean up old .csv files 
                             `n4. Exit
                             `n`nEnter choice [1 - 4]: "

        if ($choice -eq '1')
            {
                $userName = Read-Host "`nUser?" #Prompts for user to look up
                Get-ADPrincipalGroupMembership $userName -Server USNYCSRV0DCP3.ANYACCESS.NET | % {($_.name).Trim()} | Out-File $saveLocation\$userName.csv -Force #Looks up User in AD on NYC domain, trims end whitespace at the end of the groups, saves csv file with users login name
                Invoke-Item $saveLocation\$userName.csv #Open CSV file from location
            }

        elseif ($choice -eq '2')
            {

                #Prompt user for 1st AD username and saves it to the path
                $user1 =  Read-Host "`nUser 1 you want to look up: "

                #Prompt user for 2nd AD username and saves it to the path
                $user2 =  Read-Host "`nUser 2 you want to look up: "
                
                #Getting both users group for group comparison
                $a = Get-ADPrincipalGroupMembership $user1 -Server USNYCSRV0DCP3.ANYACCESS.NET | select -expand name | sort-object -unique
                $b = Get-ADPrincipalGroupMembership $user2 -Server USNYCSRV0DCP3.ANYACCESS.NET | select -expand name | sort-object -unique

                #Grabs users login name and gets users Full Name and puts it in $a and $b. This is used for the Excel key at the bottom of the sheet
                $namea = (get-aduser $user1).name
                $nameb = (get-aduser $user2).name

                Compare $a $b -IncludeEqual | Export-Csv $saveLocation\$csvFile -NoTypeInformation #compare user groups
                Add-Content $saveLocation\$csvFile " " #Creates blank row for spacing
                Add-Content $saveLocation\$csvFile " " #Creates blank row for spacing
                Add-Content $saveLocation\$csvFile "Key: " #Information for bottom of excel document
                Add-Content $saveLocation\$csvFile "== Both users are a member" #Information for bottom of excel document
                Add-Content $saveLocation\$csvFile "=> Only $nameb is a member" #Information for bottom of excel document
                Add-Content $saveLocation\$csvFile "<= Only $namea is a member" #Information for bottom of excel document

                Write-Host "`nExporting to CSV" -ForegroundColor Cyan #Informs of current process

                Invoke-Item $saveLocation\$csvFile #Opens CSV File in excel
            }

        elseif ($choice -eq '3')
            {
                Get-ChildItem -Path $location *.csv | foreach { Remove-Item $_.FullName } #Hunts down .csv extensions and deletes them
                Write-Host "`nJunking all .csv files... " -ForegroundColor Cyan #Informs user of process
            }

        elseif ($choice -eq '4')
            {
                Exit
            }

        $restart = Read-Host "`nRe-run script? [Y/N]: " #Prompts user to restart the script or end it

    }

    <#
        Compile a list of groups to exclude.
            - Regex(?)
            - With this list create a new copied list with the groups removed
            - EX: USB-Exception should be excluded into a new copied list so that way we can OnBoard users without
                unnecessarry groups
    #>