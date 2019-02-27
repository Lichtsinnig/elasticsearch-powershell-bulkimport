# Elasticsearch Bulk Import Powershell Module
Powershell module which is optimised for fast import process.
Please be aware that, this powershell script is only supports index action which creates the indices automatically

So the file content should be like

{ "field1" : "value1" }

{ "field1" : "value1" }

{ "field1" : "value1" }

{ "index":{}} will be added for each line by script which also keeps the file size less.

Script has tested on a 12.800.000 rows with a file size 4 gb

Total completion time is 12 minutes

#### PC Configuration: 

Windows 10 64 Bit

Intel Xeon CPU E3-1535M v5 @ 2.90GHz

32 GB Ram

### Step 1: Export data in json format
To generate, we will run the bcp command at below from command prompt which is fast way to export for big-data

`bcp "SELECT (SELECT Name, Surname FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) FROM [Database].[dbo].[Table];" queryout C:\export.json -c -S ".\SQLExpress" -d master -U "sa" -P "XXXX"' -e c:\error_out.log -o c:\output_out.log -T`

### Step 2: Disable some indexing settings to improve bulk index performance
Run the following api call on Kibana Devtools console (or any http client) to improve the bulk index api performance

Reference: https://www.elastic.co/guide/en/elasticsearch/reference/master/tune-for-indexing-speed.html

```
PUT /_settings {

  "index" : {
  
     "refresh_interval" : "-1",
     
     "number_of_replicas" : "0"
     
   }
   
}
```

### Step 3: Import generated authlogs json file into Elasticsearch
To import generated authlogs json file, we will use the following powerscript module file BulkElasticSearchImport.psm1

- Import the module with the following command line: Import-Module .\BulkElasticSearchImport.psm1
- Remove the module with the following command line: Remove-Module BulkElasticSearchImport
- Set 10000 max line count for optimum performance. it takes approximately 12 minutes for 12 millions row

Usage: ` Bulk-Import ".\export.json" 10000 "http://localhost:9200/indexname/doc/" "username" "password" `

### Step 4: Revert back indexing settings to their default values
Run the following api call on Kibana Devtools console or any http client

```
PUT /_settings {

  "index" : {
  
     "refresh_interval" : "1s",
     
     "number_of_replicas" : "1"
     
   }
   
}
```

### Step 5:  Explicitly refresh the index to make all operations performed for search
```
POST /indexname/_refresh
```
