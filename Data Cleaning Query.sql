-- Data Cleaning 

SELECT *
FROM layoffs;

-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values / Blank Values 
-- 4. Remove Any Columns 

-- Create a table we can manipulate. Don't ever use the raw table for this! In case we do any mistakes, it won't affect the raw data. 
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * 
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- 1. Remove Duplicates

-- creates a table that adds a column to see if there are any duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Checking an example from the output above to see if it's actually a duplicate
SELECT * 
FROM layoffs_staging 
WHERE company = "Casper";

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- Final table without the duplicates 
SELECT *
FROM layoffs_staging2;


-- 2. Standardizing Data

-- removing any white spaces
SELECT company,TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT(industry) -- checking the next column to see if there is anything to fix.
FROM layoffs_staging2
ORDER BY 1;
-- seems like we need to look into crypto and the blanks/nulls which we will do later 
SELECT * -- checking out the crypto columns
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2 -- chaning the crypto currency to just crypto since it was an error
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- let's look at more columns, or at least most. 
SELECT DISTINCT(country)
FROM layoffs_staging2
ORDER BY 1;

-- found that there United States was listed twice, once with a period. 
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY country DESC;

SELECT DISTINCT(country), TRIM(TRAILING '.' FROM country) -- removes a period
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- change date to date format and column
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= str_to_date(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2 -- only do this to a staging table
MODIFY COLUMN `date` DATE; 

SELECT DISTINCT stage -- all other columns look good!!
FROM layoffs_staging2;


-- 3. Null / Blank Values

SELECT * -- these could maybe be deleted? not needed 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2 -- setting all the blanks to null before updating them with the data
SET industry = NULL 
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '' ;

SELECT * -- we can see that this airbnb willl have to be a travel industry 
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL ;

UPDATE layoffs_staging2 t1 -- updated the industries with the industry value from other data 
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL ; 

SELECT *
FROM layoffs_staging2 
WHERE company LIKE 'Bally%';

SELECT * -- these could maybe be deleted? not needed 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- 4. Delete Columns/Rows
SELECT *  -- no more need for row_num column 
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- Final clean Data!
SELECT * 
FROM layoffs_staging2;