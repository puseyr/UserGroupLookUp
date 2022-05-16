<# User Group Look up and .csv clean up script by Ron Pusey
    Deployed: 9/29/2021
    Version: 2.00.00
#>
#Get users Credentials to validate against domain.
$UserCredential = Get-Credential 

#Save location Variable change this to save to your location of choice.
$saveLocation ='\\nas\install\Scripts\Powershell\User Group Look up' 

#CSVFile Naming convention for Month / Day / Year @ Hour:Minute:Seconds
$csvFile = "UserCompare - $(get-date -f MMM-dd-yyyy_@hh-mm-ss).csv" 


#While loop to keep the script running. While $Restart does not = n the script will keep running
while ($restart -ne 'n')
    {
        <#param 
        (
            []
        )#>
        #Script pauses and prompts the user to choose one of three options. Look up one users group, Look up two users and compare their groups, clean out .csv files from piling up
        $choice = Read-Host "`n`nChoose the following options 
                             `n1. User Group Look up for Single user 
                             `n2. User Group Look Up + Compare  
                             `n3. Clean up old .csv files 
                             `n4. Exit 
                             `n`nEnter choice [1 - 4]: "

        if ($choice -eq '1')
            {
                #Prompts for user to look up
                $userName = Read-Host "`nUser?" 

                #Looks up User in AD on NYC domain, trims end whitespace at the end of the groups, saves csv file with users login name
                Get-ADPrincipalGroupMembership $userName -Server USNYCSRV0DCP3.ANYACCESS.NET | % {($_.name).Trim()} | Out-File $saveLocation\$userName.csv -Force 

                #Open CSV file from location in Excel
                Invoke-Item $saveLocation\$userName.csv 
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

                #Informs of current process
                Write-Host "`nExporting to CSV" -ForegroundColor Cyan 

                #Opens CSV File in excel
                Invoke-Item $saveLocation\$csvFile 
            }

        elseif ($choice -eq '3')
            {   
                #Hunts down .csv extensions and deletes them
                Get-ChildItem -Path $location *.csv | foreach { Remove-Item $_.FullName } 

                #Informs user of process
                Write-Host "`nJunking all .csv files... " -ForegroundColor Cyan 
            }
        elseif ($choice -eq '4')
            {
                #Exit
                Get-ADGroupMember -identity "G-US-NYC-AP-Java Exception Computers" | select name | Export-csv -path c:\users\rpusey-sa\ -Notypeinformation
            }
        elseif ($choice -ne '1' -or '2' -or '3' -or '4' )
            {
                $restart2 = Write-Host "`nPlease choose options 1 - 4 `n1. User Group Look up for Single user `n2. User Group Look Up + Compare  `n3. Clean up old .csv files `n4. Exit `n`nEnter choice [1 - 4]: "
                Return
            }
        

        $restart = Read-Host "`nRe-run script? [Y/N]: " #Prompts user to restart the script or end it

        <#else
            {
                $restart = Read-Host "`nRe-run script? [Y/N]: " #Prompts user to restart the script or end it
                if ($restart -eq 'Y')
                    {
                        Continue
                    }
                elseif ($restart -eq 'N') 
                    {
                        Exit
                    }
            }#>



        <#if ($restart -eq 'Y')
            {
                Continue
            }
        elseif ($restart -ne 'Y' -or $restart -ne 'N')
            {
                $restart = Write-Host "`nPlease use 'Y' or 'N' (not case sensitive) "
                Continue
            }
        else 
            {
                $restart = Write-Host "`nPlease use 'Y' or 'N' (not case sensitive) "
                Continue
            }#>

            #$restart = Read-Host "`nRe-run script? [Y/N]: " #Prompts user to restart the script or end it

    }

     <#
        Feature Request:
            1. Create new list with excluded groups for easier copying
                A. Auto add said groups to copied user without manual copy-paste
                - Regex(?)
                - With this list create a new copied list with the groups removed
                - EX: USB-Exception should be excluded into a new copied list so that way we can OnBoard users without
                      unnecessarry groups
            2. Make it accessible on a web portal / sharepoint
            4. Change <=, => to user names or something a bit more identifiable
            3. Get the AD Tool working up on a sharepoint site so to speak kind of like Floor Mapper
        Bugs to fix:
            1. String validation 1-4 and Y/N
            2. Make sure loop ends correctly
    #>