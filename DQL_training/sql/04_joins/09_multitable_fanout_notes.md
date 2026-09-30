## DRILL 42: Why did rows dissapear

The dissapearing rows are values from the fact table that are not present in the respective dimesion tables. The query joined fact table to the dimension tables using inner join where all the values in fact table and dimension tables that are present in both tables will be preserved. The values that are present in the fact tables but absent in the dimension tables dissapear from the output table.
