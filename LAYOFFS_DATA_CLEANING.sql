CREATE DATABASE PROJECT_DC;

SELECT * FROM LAYOFFS;

-- FIRST INSIGHT 
-- NULL AND BLANKS ARE THERE 
-- CHECKING THE DTYPES OF ALL THE COLUMN -- DATE IS STRING 

-- Create Staging tables to preserve original data 

CREATE TABLE LAYOFFS_STAGING 
LIKE LAYOFFS;

SELECT * FROM layoffs_staging;

-- Insert data into staging table from layoffs

INSERT layoffs_staging
SELECT * FROM layoffs;

SELECT * FROM layoffs_staging;

-- Now that staging table is complete thorough data clenaing can start
	-- Duplicated
    -- removing columns 
    -- Standardization 
-- DEALING WITH NULLS 
-- CHECKING UNIQUE VALUES OF COLUMN IF REDUNDENT VALUES ARE THERE
-- REMOVING WHITE SPACES 
-- DEALING WITH DATE COLUMN LIKE EXTRACTING YEAR, DAY, MONTH IF REQUIRED 
-- FORMATING OF DATE 


-- DEALING WITH DUPLICATES 

-- I CAN SEE THERE IS NO UNIQUE INDENTIFIER FOR ROWS 

WITH DUPLICATE_CTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE, STAGE, COUNTRY, funds_raised_millions) AS ROW_NUM
FROM layoffs_staging 
)

SELECT * 
FROM DUPLICATE_CTE 
WHERE ROW_NUM>1

-- 5 rows appear to be duplicates 

 -- REMOVING THE DUPLICATES 
 
 -- TO DELETE THE DUPLICATES I WILL CREATE A NEW TABLE STAGING 2 COMBINING THE ROW_NUM AND THEN DELETE FROM THAT TABLE
 
 CREATE TABLE LAYOFFS_STAGGING2( 
	company text,
	location text ,
	industry text ,
	total_laid_off int ,
	percentage_laid_off text ,
	date text ,
	stage text ,
	country text ,
	funds_raised_millions int,
	row_num int -- row num added 
);


SELECT * FROM LAYOFFS_STAGGING2;

-- INSERTING ALL THE DATE FROM LAYOFF_STAGING WITH ROW NUM
INSERT layoffs_stagging2
SELECT *, ROW_NUMBER() OVER (PARTITION BY COMPANY, LOCATION, INDUSTRY, TOTAL_LAID_OFF, PERCENTAGE_LAID_OFF, DATE, STAGE, COUNTRY, funds_raised_millions) AS ROW_NUM
FROM layoffs_staging ;

SELECT * 
FROM layoffs_stagging2
WHERE ROW_NUM>1;

-- NOW READY WITH A TABLE TO DELETE DUPLICATE
 
 
 DELETE FROM layoffs_stagging2
 WHERE ROW_NUM>1;
 
 
 
-- Check table doe snto have row_num >1 
SELECT * 
FROM layoffs_stagGing2 
WHERE row_num >1; -- result is 0 

SELECT COUNT(*) 
FROM layoffs_stagging2; -- 2356

SELECT COUNT(*) 
FROM layoffs_staging; -- 2361

-- Standardizing data 
-- I can see company name was spacing differences 
    
SELECT * 
FROM layoffs_stagging2;

SELECT TRIM(COMPANY)
FROM layoffs_stagging2;

UPDATE LAYOFFS_STAGGING2
SET COMPANY = TRIM(COMPANY);

-- NOW CHECKING DISTINCT VALUE OF CATEGORIES 

SELECT distinct(INDUSTRY) 
FROM layoffs_stagging2
ORDER BY 1;

-- I FOUND  crypto, nulls and blanks should be handled 

-- FIRST REPLACING CRYPTO 

SELECT INDUSTRY 
FROM layoffs_stagging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_stagging2
SET INDUSTRY = 'Crypto' 
WHERE industry LIKE 'Crypto%';

-- VERIFYING 
SELECT distinct(INDUSTRY) 
FROM layoffs_stagging2 
WHERE industry LIKE 'Crypto%';

SELECT * 
FROM layoffs_stagging2;

SELECT DISTINCT(stage)
FROM layoffs_stagging2
ORDER BY 1;

SELECT DISTINCT(COUNTRY)
FROM layoffs_stagging2
ORDER BY 1;

-- I FOUND United States has 2 naming methods

Update layoffs_stagging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Verify it changed to 'United States'
SELECT DISTINCT(COUNTRY)
FROM layoffs_stagging2
WHERE country LIKE 'United States%';
 
SELECT * FROM layoffs_stagging2;


-- NOW LET US DEAL DATE COLUMN DATATYPE 

-- FIRST LET ME CORRECT THE FORMAT 
SELECT STR_TO_DATE(DATE, '%m/%d/%Y')
FROM layoffs_stagging2;

UPDATE layoffs_stagging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

SELECT DATE FROM layoffs_stagging2;

ALTER TABLE layoffs_stagging2 MODIFY DATE DATE;

SELECT * 
FROM layoffs_stagGing2;


-- Next, handle the following in various columns
-- - Blank values 
-- - Null values 

-- DEALING WITH COUNTRY INDUSTRY FIRST 

-- Change the blank values to NULL and then join the tables from t1. to t2 for industry 
 
 UPDATE layoffs_stagging2
SET industry = NULL
WHERE industry = ''; 

-- Check blanks changed to NULL 
SELECT INDUSTRY
FROM layoffs_stagging2
WHERE INDUSTRY = '';

SELECT t1.industry, t2.industry
FROM layoffs_stagging2 t1
JOIN layoffs_stagging2 t2 
	ON t1.company = t2.company 
    AND t1.location = t2.location
WHERE (t1.industry IS NULL or t1.industry = '')
AND t2.industry IS NOT NULL;

-- Update table from NULL and fill NULL with industry for same company name 
UPDATE layoffs_stagging2 t1
JOIN layoffs_stagging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Review it worked 
SELECT *
FROM layoffs_stagging2 
WHERE industry IS NULL;
 
-- Bally's Interactive did not change
-- I can either ask the team about the industry and reasearch on this or 
-- drop this row 

-- After research it was found that Bally's Interactive is in the gaming industry
-- Update the industry to gaming 

UPDATE layoffs_stagging2
SET industry = 'Gaming'
WHERE industry IS NULL;

-- DEALING WITH OTHER COLUMNS NOW, 

SELECT *
FROM layoffs_stagging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Deleting total laid off and percentage laid off are NULL
-- Keeping this data would effect the EDA

DELETE 
FROM layoffs_stagging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_stagging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- Now I've completed all the data cleaning now, I can drop the row_num as it doesn't add any value (also to the EDA process)
ALTER TABLE layoffs_stagging2
DROP COLUMN row_num;


SELECT *
FROM layoffs_stagging2;


