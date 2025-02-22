# Data Cleaning Project

## 1. Project Overview

The objective of this project was to clean and standardize the layoffs dataset for accurate analysis. This involved identifying and handling duplicates, null values, blank entries, inconsistent formatting, and incorrect data types. The entire process was performed in MySQL, following a structured approach to maintain data integrity.

---

## 2. Setting Up the Project

### Step 1: Creating a New Database and Importing Data

First, I created a new database named `PROJECT_DC` and imported the raw `LAYOFFS` table into it. This ensured that all data cleaning steps would be carried out in a separate environment without altering the original dataset.

```sql
CREATE DATABASE PROJECT_DC;
USE PROJECT_DC;
SELECT * FROM LAYOFFS;

```
Upon inspecting the table, I noticed several issues:

Duplicate rows
Null and blank values
Inconsistent formatting (e.g., country names)
Date column stored as a string instead of a date datatype
To avoid affecting the original table, I created a staging table for all cleaning tasks.
```

CREATE TABLE LAYOFFS_STAGING
LIKE LAYOFFS;

INSERT INTO LAYOFFS_STAGING
SELECT * FROM LAYOFFS;

```
## 3. Data Cleaning Steps
3.1 Handling Duplicates
Since there was no unique identifier for rows, I used ROW_NUMBER() with PARTITION BY to identify duplicate entries based on key columns like company, location, industry, layoffs, date, and stage.

```

WITH DUPLICATE_CTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS) AS ROW_NUM
FROM LAYOFFS_STAGING
)

SELECT * FROM DUPLICATE_CTE WHERE ROW_NUM > 1;

```
I found 5 duplicate rows. To safely remove them, I created another staging table, LAYOFFS_STAGGING2, including the ROW_NUM column.

```

CREATE TABLE LAYOFFS_STAGGING2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT,
    percentage_laid_off TEXT,
    date TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT,
    row_num INT
);

INSERT INTO LAYOFFS_STAGGING2
SELECT *, ROW_NUMBER() OVER (PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE, STAGE, COUNTRY, FUNDS_RAISED_MILLIONS) AS ROW_NUM
FROM LAYOFFS_STAGING;

```
I deleted the duplicate entries where ROW_NUM > 1.

```

DELETE FROM LAYOFFS_STAGGING2
WHERE ROW_NUM > 1;

```
To verify the result, I checked the count before and after:

Original count: 2361 rows
After removing duplicates: 2356 rows

## 3.2 Standardizing Data
1. Trimming White Spaces:
Company names had extra spaces, so I used the TRIM() function to clean them.

```
UPDATE LAYOFFS_STAGGING2
SET COMPANY = TRIM(COMPANY);

```

2. Handling Industry Values:
I found inconsistent values like Crypto written as Crypto.com. I replaced them with a standard term.

```

UPDATE LAYOFFS_STAGGING2
SET INDUSTRY = 'Crypto'
WHERE INDUSTRY LIKE 'Crypto%';

```

3. Handling Country Values:
Similarly, the country United States appeared as United States of America. I standardized this as well.

```

UPDATE LAYOFFS_STAGGING2
SET COUNTRY = 'United States'
WHERE COUNTRY LIKE 'United States%';

  ```

##3.3 Date Column Standardization
The DATE column was stored as a string. I converted it into a proper date format using STR_TO_DATE() and modified the column datatype.
```

UPDATE LAYOFFS_STAGGING2
SET `DATE` = STR_TO_DATE(`DATE`, '%m/%d/%Y');

ALTER TABLE LAYOFFS_STAGGING2
MODIFY `DATE` DATE;

```

## 3.4 Handling Null and Blank Values
1. Industry Column:
I first converted blank values to NULL.

```
UPDATE LAYOFFS_STAGGING2
SET INDUSTRY = NULL
WHERE INDUSTRY = '';

```
Then, I filled the NULL values using the industry of the same company from other rows.

```

UPDATE LAYOFFS_STAGGING2 t1
JOIN LAYOFFS_STAGGING2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

```

For Bally's Interactive, manual research revealed it belongs to the Gaming industry. So, I updated it accordingly.

```
UPDATE LAYOFFS_STAGGING2
SET INDUSTRY = 'Gaming'
WHERE INDUSTRY IS NULL;


```
2. Total Laid Off and Percentage Laid Off:
Rows with both values as NULL were not useful, so I deleted them.
```

DELETE FROM LAYOFFS_STAGGING2
WHERE TOTAL_LAID_OFF IS NULL
AND PERCENTAGE_LAID_OFF IS NULL;

```
3.5 Final Cleanup
After cleaning, the ROW_NUM column was no longer needed, so I dropped it.

```
ALTER TABLE LAYOFFS_STAGGING2
DROP COLUMN ROW_NUM;

```
4. Conclusion and Insights
After completing the cleaning process, I achieved the following outcomes:

Duplicates Removed: 5 duplicate rows were deleted.
Standardized Values: Company names, industry, and country fields were cleaned.
Date Format Fixed: The date column was converted from string to proper date format.
Null and Blanks Handled: Missing values were either filled using existing data or removed if they were unusable.
Final Row Count: 2353 rows.
This cleaned dataset is now ready for further Exploratory Data Analysis (EDA) and visualization.

```




