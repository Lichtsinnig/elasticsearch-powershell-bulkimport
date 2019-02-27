 ## Index information should be passed as parameter and should not be included into json file which cause bigger file sizes 
 ## First Import the module with the following command line: Import-Module .\BulkElasticSearchImport.psm1 
 ## Don't forget to remove module after use it with the following command line: Remove-Module BulkElasticSearchImport

 ## Usage: Bulk-Import ".\Jsonfile.json" 10000 "http://localhost:9200/indexname/doc/" "username" "password"
 ## Tip: Set 10000 max line count for optimum performance. it takes approximately 12 minutes for 12 millions row

Add-Type -AssemblyName System.Net.Http
$httpClient = New-Object System.Net.Http.Httpclient
$method =  New-Object System.Net.Http.HttpMethod("POST")
$contentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/x-ndjson");

function BulkRequest([string]$url, [System.Text.StringBuilder]$bulkIndexLines) {	
	$message = New-Object System.Net.Http.HttpRequestMessage($method, $url)
	
	$message.Content = New-Object System.Net.Http.StringContent($bulkIndexLines.ToString())
	$message.Content.Headers.Clear()
	$message.Content.Headers.ContentType = $contentType
	
	$response = $httpClient.SendAsync($message).Result
	
	[void]$response.EnsureSuccessStatusCode()
}

function Bulk-Import([string]$filePath, [int]$maxLineCount, [string]$url, [string]$username, [string]$password) {
	$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($username + ":" + $password))	 	
	$httpClient.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue("Basic", $encodedCredentials);

	$url = [Uri]::new([Uri]::new($url), "_bulk").ToString() 
	$newLine = "`r`n" 	
	$indexInfo = "{""index"":{}}" + $newLine 	
	$lineCount = 0
	$bulkIndexLines = [System.Text.StringBuilder]::new()

	$file = New-Object System.IO.StreamReader -Arg $filePath
	try {
		Write-Host "Import Process started on $(Get-Date)" -ForegroundColor Yellow -BackgroundColor Black

		while ($line = $file.ReadLine()) {
			[void]$bulkIndexLines.AppendLine($indexInfo + $line)
			$lineCounts++
			if(($lineCounts % $maxLineCount) -eq 0) {			
				BulkRequest $url $bulkIndexLines
				Write-Host "`r$lineCounts lines have processed" -NoNewline -ForegroundColor White -BackgroundColor Black			
				[void]$bulkIndexLines.Clear()
			}	  	
		}

		if($bulkIndexLines.Length -gt 0) {
			BulkRequest $url $bulkIndexLines		
			Write-Host "`r$lineCounts lines have processed" -NoNewline -ForegroundColor White -BackgroundColor Black			
			[void]$bulkIndexLines.Clear()
		}

		Write-Host $newLine"Import Process has completed successfully on $(Get-Date)" -ForegroundColor Green -BackgroundColor Black		
	}
	catch {		
		Write-Host $newLine"Import Process failed on $(Get-Date)" -ForegroundColor Red -BackgroundColor Black
		Write-Host "Exception: $_.Exception.Message" -ForegroundColor Red -BackgroundColor Black    	
	}
	finally {
		[void]$bulkIndexLines.Clear()
		$file.close()
	}
}

Export-ModuleMember -Function Bulk-Import