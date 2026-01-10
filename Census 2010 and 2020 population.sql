# Census Census 2010 and 2020 Population: 
# Region, Counties, Cities, Towns, Villages
# in NYC project

SELECT *
FROM census;

# Potential NULL Values are being checked. None detected.

SELECT *
FROM census
WHERE `Area Type` IS NULL OR  `Area Name` IS NULL OR `Population Percent Change` IS NULL OR
`2010 Census Population` IS NULL OR `2020 Census Population` IS NULL OR `Population Change` IS NULL 
OR `Population Percent Change` IS NULL
;

# Potential 0 Values are being checked.

SELECT *
FROM census
WHERE `Area Type` = '' OR  `Area Name` = '' OR `Population Percent Change` = 0 OR
`2010 Census Population` = 0 OR `2020 Census Population` = 0 OR `Population Change` = 0 
OR `Population Percent Change` = 0
;

# The returned 3 values are results of an operation rather than being blank, so no 0 values are present.

SELECT `Area Type`, COUNT(`Area Type`)
FROM census
GROUP BY `Area Type`;

# Checking for possible duplicates with the help of count function

SELECT `Area Name`, COUNT(`Area Name`)
FROM census
GROUP BY `Area Name`
HAVING COUNT(`Area Name`) > 1
;

# In order to determine if those rows are indeed the possible duplicates, the whole rows that...
# ... belong to those possible duplicate have to be queried and visualized.

SELECT *
FROM census
WHERE `Area Name` LIKE '%New York City%' OR `Area Name` LIKE '%Dickinson Town%' OR `Area Name` LIKE '%Chester Town%'
OR `Area Name` LIKE '%Greenville Town%' OR `Area Name` LIKE '%Brighton Town%' OR `Area Name` LIKE '%Franklin Town%' 
OR `Area Name` LIKE '%Lewis Town%' OR `Area Name` LIKE '%Albion Town%' OR `Area Name` LIKE '%Clinton Town%'
OR `Area Name` LIKE '%Ashland Town%' OR `Area Name` LIKE '%Fremont Town%' OR `Area Name` LIKE '%Morris Town%' 
OR `Area Name` LIKE '%York Town%' OR `Area Name` LIKE '%Beekman Town%' OR `Area Name` LIKE '%German Town%' 
OR `Area Name` LIKE '%Orange Town%'
;

# Upon visualizing the rows, it has been determined that none of the rows are duplicates. The 'New York City'...
#... row that has exactly the same values aren't considered as duplicate because it belongs to 2 different...
#... such as City and REDC.

# In the `Area Name` column, there are some entries which include the word 'town' more than once, so those rows...
# have to be identified first. REGULAR EXPRESSIONS and METACHARACTERS are going to be used for this query for identifying.
# At first, the entries in Area Name column that has 'town' has been determined, with the help us using the COUNT function...
# ... which enables to separate the rows that has 'town' in them.

SELECT `Area Name`, REGEXP_LIKE (`Area Name`,'town') AS names_including_town
FROM census
GROUP BY `Area Name`
HAVING names_including_town > 0
;

# After the determination of the rows that has 'town' in them, now the determination of...
# ... the names that ends with 'town' has been initiated.

SELECT `Area Name`
FROM census
WHERE `Area Name` REGEXP 'town$'
;

# After identyfing the rows that include 'town' at the end, the spaces between each words are removed...
# ... so that the names in the rows became one word with the help of REGEXP_REPLACE command and...
# using a SUBQUERY to be able to select the only ones that include the word 'town.' at the end.

SELECT `Area Name`, REGEXP_REPLACE(`Area Name`, '[ ]', '')
FROM census
WHERE `Area Name` IN
	(SELECT `Area Name`
	FROM census
	WHERE `Area Name` REGEXP 'town$'
	)
;

# Updating the database after the modification.

UPDATE census
SET `Area Name` = REGEXP_REPLACE(`Area Name`, '[ ]', '')
WHERE `Area Name` REGEXP 'town$'
;

# As visualized here, all the names that have 'town' at the end, were deprived of the spices...
# ... so that the second 'town' at the end can be removed. Only these 21 rows will be targeted.

SELECT `Area Name`
FROM census
WHERE `Area Name` REGEXP 'towntown$'
;

# Removing the second 'town' from the end of the names.

SELECT `Area Name`, REGEXP_REPLACE(`Area Name`,'towntown', 'town')	
FROM census
WHERE `Area Name` REGEXP 'towntown$'
;

# Removing the second 'town' from the end of the names.

UPDATE census
SET `Area Name` = REGEXP_REPLACE(`Area Name`,'towntown', 'town')
WHERE `Area Name` REGEXP 'town$'
;

# Proving that those 'towntown' are converted to town.

SELECT *
FROM census
WHERE `Area Name` REGEXP 'towntown$';

# In order to defragment all the words that include 'town', this combination has been selected. To separate...
# ... the rest of the name from 'word', 'word' has been selected as the delimiter within the name in the...
# ... SUBSTRING_INDEX command and then a blank has been added before adding the 'town' and combining... 
# ... all 3 of those fragments with CONCATENATE command.



# Applying the update

UPDATE census
SET `Area Name` = CONCAT(SUBSTRING_INDEX(`Area Name`,'town',1),' ',RIGHT(`Area Name`,4))
WHERE `Area Name` REGEXP 'town$'
;

# Determining names with '-' and removing them.

SELECT `Area Name`, REGEXP_REPLACE(`Area Name`,'-',' ')
FROM census
WHERE `Area Name` REGEXP '-'
;

# Applying those changes

UPDATE census
SET `Area Name` = REGEXP_REPLACE(`Area Name`,'-',' ')
WHERE `Area Name` REGEXP '-'
;

# Double-Check on the updated names

SELECT `Area Name`
FROM census
WHERE `Area Name` REGEXP '-'
;

SELECT *
FROM census
;

# Now, we are in EDA phase. Checking if the 'Population Change' Column has been calculated correctly.
# The same process is going to be applied to the 'Population Percent Change' column as well with...
# ... the help CASE statement where we compare the columns to the manually described operation in....
# ... order to determine if they match. If they don't, corrections will be applied.

SELECT *
FROM
(SELECT `Population Change`,
CASE 
WHEN `2020 Census Population` - `2010 Census Population` = `Population Change` THEN TRUE
ELSE FALSE
END AS Population_Difference_Comparison
FROM census) AS Check_Table
WHERE Population_Difference_Comparison = 0
;

SELECT `Population Percent Change`,
CASE 
WHEN (`2020 Census Population` - `2010 Census Population`) / `2010 Census Population` = `Population Percent Change` THEN TRUE
ELSE FALSE
END AS Population_Percent_Change_Comparison
FROM census
;

# As seen here above, except for few rows, most of the rows do not match at all. This needs to be addressed.
# As it can be noticed in the query, there are only 4 digits visible, so those digits are going to be...
# ... ROUNDed to 4 decimals.

SELECT *
FROM
(
SELECT `Population Percent Change`,
CASE 
WHEN ROUND((`2020 Census Population` - `2010 Census Population`) / `2010 Census Population`,4) = `Population Percent Change` THEN TRUE
ELSE FALSE
END AS Population_Percent_Change_Comparison
FROM census
) AS ppcr_Table
WHERE Population_Percent_Change_Comparison = 0
;

SELECT ROUND(`Population Percent Change` ,2)
FROM census
;

# A better way of displaying the population percent change by displaying as percentages rounded to 2 decimals.

SELECT *,
RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'City' AND `Population Change` >= 0
;

# Here is being shown all the cities in which their population has increased and they have been ranked from...
# ... the most to the least.

SELECT *,
DENSE_RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` ASC) AS Population_Decrease_Ranking
FROM census
WHERE `Area Type` = 'City' AND `Population Change` <= 0
;

# Here is being shown all the cities in which their population has decreased and they have been ranked from...
# ... the least to the most. And DENSE_RANK has been chosen here to show that after `Ogdensburg City' and...
# ... 'Oneida City' which have exactly the same amount of people emigrating, comes the rank 22 instead of 23...
# ... because there are double 21st ranking.

SELECT *,
RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'County' AND `Population Change` >= 0
;

SELECT *,
RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'County' AND `Population Change` <= 0
;

SELECT *,
DENSE_RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'Town' AND `Population Change` >= 0
;

SELECT *,
DENSE_RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'Town' AND `Population Change` <= 0
;

SELECT *,
DENSE_RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'Village' AND `Population Change` >= 0
;

SELECT *,
DENSE_RANK() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Population_Increase_Ranking
FROM census
WHERE `Area Type` = 'Village' AND `Population Change` <= 0
;

# All of the population ranking determination methods have been applied to the County, City, Town and Village rows...
# ... respectively. DENSE_RANK function has been prefferred because of the sequential number preference in ranking.

SELECT *
FROM
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` DESC) AS Row_Num
FROM census
WHERE `Area Type` = 'Village' AND `Population Change` >= 0) AS Row_Table
WHERE Row_Num <= 5
;

# In thE final phase of the DEA phase, the villages that have the top 5 population increase have been queried.
# In the subquery, the row number table has been generated so that the top 5 villages can be queried through..
# ... our main query by choosing from the assigned row numbers to the villages by the ROW_NUMBER function.

SELECT *,
ROW_NUMBER() OVER(PARTITION BY `Area Type` ORDER BY `Population Change` ASC) AS Row_Num
FROM census
WHERE `Area Type` = 'Town' AND `Population Change` <= 0
LIMIT 7
;

# Here the top 7 population decrease in 'Town' have been querried. Again, ROW_NUMBER function has been chosen.
# This time LIMIT has been opted the determine the top 7 towns.

