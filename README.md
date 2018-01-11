# SQL_DDL_Generator
Provides a basic SQL DDL statement for a Table/View. 

Created this SPROC after realizing that SQL Server does not  provide a way to programatically create 
DDL for tables / views. The only way that I am aware of to get this information in SQL Server is 
through the GUI, which is not always efficient.  

For tables and views. this will provide a partial DDL "Create" statement programatically.
The following aspects of the DDL statement are included based on my specific use case.
* Table/View name
* Schema
* Basic formatting of create statment
* Column names
* Columns data types
* Identity columns (including seed_value and increment_value)

