Try {
    [Reflection.Assembly]::LoadFile($pwd.Path + "\OrcaMDF.RawCore.dll") | Out-Null
    [Reflection.Assembly]::LoadFile($pwd.Path + "\OrcaMDF.Framework.dll") | Out-NUll
} Catch {
    Write-Host "Could not load OrcaMDF libraries, please make sure that you run Import-Module from the dir containing OrcaMDF.RawCore.dll and OrcaMDF.Framework.dll"
}

function Get-MDFHashes
{
    [CmdletBinding()]Param (
    [Parameter(Mandatory = $True, ParameterSetName="mdf")]
    [String]$mdf
    )
    
    $instance = New-Object "OrcaMDF.RawCore.RawDataFile" $mdf

    $records = $instance.Pages | where {$_.Header.ObjectID -eq 34 -and $_.Header.Type -eq 1} | select -ExpandProperty Records
    
    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name")
               )
    
    $sysxlgns_id = 0

    foreach($r in $records) {
            Try {
                $row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
                
                if ($row.name -eq "sysxlgns") {
                    $sysxlgns_id = $row.id
                }

            } Catch {
                # silently continue
            }
    }

    if ($sysxlgns_id -eq 0) {
        Write-Host "Could not find sysxlgns ObjectID in database"
        return @{}
    }


    $records = $instance.Pages | where {$_.Header.ObjectID -eq $sysxlgns_id -and $_.Header.Type -eq 1} | select -ExpandProperty Records

    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name") 
                [OrcaMDF.RawCore.Types.RawType]::VarBinary("sid")
                [OrcaMDF.RawCore.Types.RawType]::Int("status")
                [OrcaMDF.RawCore.Types.RawType]::Char("type", 1)
                [OrcaMDF.RawCore.Types.RawType]::DateTime("crdate")
                [OrcaMDF.RawCore.Types.RawType]::DateTime("modate")
                [OrcaMDF.RawCore.Types.RawType]::Sysname("dbname")
                [OrcaMDF.RawCore.Types.RawType]::Sysname("lang")
                [OrcaMDF.RawCore.Types.RawType]::VarBinary("pwdhash")
               )

    $results = @()

    foreach($r in $records) {

        Try {
            $row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
			
			$result = New-Object -TypeName PSObject
			Add-Member -InputObject $result -MemberType NoteProperty -Name "UserName" -Value $row.name
			
            if ($row.pwdhash) {
				Add-Member -InputObject $result -MemberType NoteProperty -Name "PasswordHash" -Value ("0x" + [BitConverter]::ToString($row.pwdhash).Replace("-", ""))
            } else {
                Add-Member -InputObject $result -MemberType NoteProperty -Name "PasswordHash" -Value "NO HASH PRESENT"
            }
			
			$results += $result
			
        } Catch {
            Write-Host "Failed to parse hash data with the defined model"
        }
    }

    return $results
}





function Get-MDFServers
{
    [CmdletBinding()]Param (
    [Parameter(Mandatory = $True, ParameterSetName="mdf")]
    [String]$mdf
    )
    
    $instance = New-Object "OrcaMDF.RawCore.RawDataFile" $mdf

    $records = $instance.Pages | where {$_.Header.ObjectID -eq 34 -and $_.Header.Type -eq 1} | select -ExpandProperty Records
    
    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name")
               )
    
    $sysxsrvs_id = 0

    foreach($r in $records) {
            Try {
                $row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
                
                if ($row.name -eq "sysxsrvs") {
                    $sysxsrvs_id = $row.id
                }

            } Catch {
                # silently continue
            }
    }

    if ($sysxsrvs_id -eq 0) {
        Write-Host "Could not find sysxsrvs ObjectID in database"
        return @{}
    }


    $records = $instance.Pages | where {$_.Header.ObjectID -eq $sysxsrvs_id -and $_.Header.Type -eq 1} | select -ExpandProperty Records

    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name")
		[OrcaMDF.RawCore.Types.RawType]::Sysname("product") 
		[OrcaMDF.RawCore.Types.RawType]::Sysname("provider") 
                [OrcaMDF.RawCore.Types.RawType]::Int("status")
                [OrcaMDF.RawCore.Types.RawType]::DateTime("modate")
                [OrcaMDF.RawCore.Types.RawType]::Sysname("catalog")
                [OrcaMDF.RawCore.Types.RawType]::Int("cid")
                [OrcaMDF.RawCore.Types.RawType]::Int("connecttimeout")
                [OrcaMDF.RawCore.Types.RawType]::Int("querytimeout")
               )

	$results = @()
    foreach($r in $records) {
		try {
			$row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
			
			$result = New-Object -TypeName PSObject
			Add-Member -InputObject $result -MemberType NoteProperty -Name "Name" -Value $row.name
			Add-Member -InputObject $result -MemberType NoteProperty -Name "Product" -Value $row.Product
			Add-Member -InputObject $result -MemberType NoteProperty -Name "Provider" -Value $row.Provider
			$results += $result
		}
		Catch 
		{
			Write-Host "Failed to parse server data with the defined model"
		}

    }
	
	return $results
}
