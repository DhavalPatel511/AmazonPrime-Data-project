/*
===================================
CLEANING AND TRANSFORMTION 
===================================
*/

----------- Clean table

IF OBJECT_ID('amazonprime_shows_cleaned', 'U') IS NOT NULL
    DROP TABLE amazonprime_shows_cleaned;


WITH deduplicated_shows AS (
    SELECT 
        show_id,
        title = LTRIM(RTRIM(title)),
        base_title = LTRIM(RTRIM(CASE WHEN CHARINDEX('(',title) > 0 THEN LEFT(title,CHARINDEX('(',title)-1) ELSE title END)),
        type = UPPER(type),
        release_year,
        rating_cleaned = 
            CASE 
                WHEN rating IN ('ALL','G','ALL_AGES','TV-Y','TV-G') THEN 'All Ages'
                WHEN rating IN ('7+','TV-Y7') THEN 'Kids 7+'
                WHEN rating IN ('PG-13','TV-PG','TV-14','13+') THEN 'Teens 13+'
                WHEN rating IN ('16+','16','AGES_16_') THEN 'Teens 16+'
                WHEN rating IN ('R','TV-MA','18+','AGES_18_','NC-17') THEN 'Adults 18+'
                WHEN rating IN ('PG','TV-PG') THEN 'Parental Guide'
                WHEN rating IN ('NR','TV-NR','UNRATED','NOT_RATE') OR rating IS NULL THEN 'Not Rated'
            END,
        duration_minutes = 
            CASE 
                WHEN duration LIKE '%Season%' THEN NULL
                ELSE TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT)
            END,
        duration_bucket = 
            CASE 
                WHEN duration LIKE '%Season%' THEN 'TV Show'
                WHEN TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT) < 60 THEN 'Short'
                WHEN TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT) BETWEEN 60 AND 90 THEN 'Medium'
                WHEN TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT) BETWEEN 91 AND 120 THEN 'Long'
                WHEN TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT) > 120 THEN 'Very Long'
                ELSE 'Unknown'
            END,
        duration_seasons = 
            CASE 
                WHEN type = 'TV SHOW' AND duration LIKE '%Season%' THEN TRY_CAST(LEFT(duration, CHARINDEX(' ', duration + ' ') - 1) AS INT)
                ELSE NULL
            END,
        description = LTRIM(RTRIM(description)),
        -- Add a row number to identify duplicates
        ROW_NUMBER() OVER (PARTITION BY UPPER(LTRIM(RTRIM(title))), UPPER(type) ORDER BY show_id) AS row_num
    FROM amazonprime_raw
    WHERE show_id IS NOT NULL
)
SELECT 
    show_id,
    title,
    base_title,
    type,
    release_year,
    rating_cleaned,
    duration_minutes,
    duration_bucket,
    duration_seasons,
    description
INTO amazonprime_shows_cleaned
FROM deduplicated_shows
WHERE row_num = 1;  -- Keep only the first occurrence of each title+type combination



SELECT * FROM amazonprime_shows_cleaned;



------ Creating a mapping table for show_ids and 
SELECT 
    raw.show_id AS original_show_id,
    cleaned.show_id AS canonical_show_id
INTO show_id_mapping
FROM amazonprime_raw raw
JOIN amazonprime_shows_cleaned cleaned 
    ON UPPER(LTRIM(RTRIM(raw.title))) = UPPER(cleaned.title) 
    AND UPPER(raw.type) = cleaned.type;

-----  Directors
IF OBJECT_ID('amazonprime_directors', 'U') IS NOT NULL
    DROP TABLE amazonprime_directors;

SELECT DISTINCT 
    m.canonical_show_id AS show_id,
    LTRIM(RTRIM(value)) AS director
INTO amazonprime_directors
FROM amazonprime_raw raw
CROSS APPLY STRING_SPLIT(ISNULL(raw.director, 'Unknown'), ',')
JOIN show_id_mapping m ON raw.show_id = m.original_show_id;


SELECT DISTINCT director 
FROM amazonprime_directors;

IF OBJECT_ID('director_name_mapping', 'U') IS NOT NULL
    DROP TABLE director_name_mapping;

CREATE TABLE director_name_mapping (
    mapping_id INT IDENTITY(1,1) PRIMARY KEY,
    alias_raw NVARCHAR(255) NOT NULL,
    director_cleaned NVARCHAR(255) NOT NULL,
    is_compound_name BIT NOT NULL DEFAULT 0,  -- Flag for compound names (multiple directors)
    canonical_position INT NULL,              -- For compound names, position in the list
);

-- Insert known variations into the mapping table
INSERT INTO director_name_mapping (alias_raw, director_cleaned) VALUES
-- Your specific examples
('Adrian Grunberg', 'Adrian Grünberg'),
('Adrian Grünberg', 'Adrian Grünberg'),
('AK.REED FILMS (Amire K Reed)', 'AK. Reed Films (Amire K Reed)'),
('AK. Reed Films (Amire k reed)', 'AK. Reed Films (Amire K Reed)'),
('AK. Reed Films  (Amire k reed)', 'AK. Reed Films (Amire K Reed)'),
------bottom one is real
('A.R. Murugadoss','A.R. Murugadoss'),
('A. R. Murugadoss','A.R. Murugadoss'),
('A. L. Vijay','A.L. Vijay'),
('A.L. Vijay','A.L. Vijay'),
('A. V. Meiyappan','A.V. Meiyappan'),
('A.V. Meiyappan','A.V. Meiyappan'),
('Swarooj RSJ','Swaroop RSJ'),
('Swaroop RSJ','Swaroop RSJ'),
('C V Kumar','C.V. Kumar'),
('C.V. Kumar','C.V. Kumar'),
('Caarthik Raju','Caarthick Raju'),
('Caarthick Raju','Caarthick Raju'),
('Claudio Fah','Claudio Fäh'),
('Claudio Fäh','Claudio Fäh'),
('Enzo Castellari', 'Enzo G. Castellari'),
('Enzo G. Castellari', 'Enzo G. Castellari'),
('Gautham Menon', 'Gautham Vasudev Menon'),
('Gautham Vasudev Menon', 'Gautham Vasudev Menon'),
('Ian Toyton','Ian Toynton'),
('Ian Toynton','Ian Toynton'),
('j ramesh','J. Ramesh'),
('J. Ramesh','J. Ramesh'),
('Jean Yarborough','Jean Yarbrough'),
('Jean Yarbrough','Jean Yarbrough'),
('Jean-Claude LaMarre','Jean Claude LaMarre'),
('Jean-Claude La Marre','Jean Claude LaMarre'),
('Jean Claude Le Marre','Jean Claude LaMarre'),
('Jean Claude LaMarre','Jean Claude LaMarre'),
('Kris Kertanian','Kris Kertenian'),
('Kris Kertenian','Kris Kertenian'),
('Mahesh Narayan','Mahesh Narayanan'),
('Mahesh Narayanan','Mahesh Narayanan'),
('Mark Knight DIrector','Mark Knight'),
('Mark Knigjht','Mark Knight'),
('Mark Knioght','Mark Knight'),
('Mark Knight','Mark Knight'),
('Mark Steven Johnson; Mark Johnson','Mark Steven Johnson'),
('Mark Steven Johnson','Mark Steven Johnson'),
('Pa.Ranjith','Pa. Ranjith'),
('Pa. Ranjith','Pa. Ranjith'),
('Sidney Furie','Sidney J. Furie'),
('Sidney J. Furie','Sidney J. Furie'),
('Spencer Gordon Bennett','Spencer Gordon Bennet'),
('Spencer Gordon Bennet','Spencer Gordon Bennet'),
('Srijit Mukherjee','Srijit Mukherji'),
('Srijit Mukherji','Srijit Mukherji'),
('Surrender Reddy','Surender Reddy'),
('Surender Reddy','Surender Reddy');


INSERT INTO dbo.director_name_mapping (alias_raw, director_cleaned, is_compound_name, canonical_position)
VALUES
    -- First director in compound names
    ('A. V. Meiyappan A. T. Krishnaswamy', 'A.V. Meiyappan', 1, 1),
    ('Yogesh Jadhav  Nitin Chavan', 'Yogesh Jadhav', 1, 1),
    ('Shiboprasad Mukherjee and Nandita Roy', 'Shiboprasad Mukherjee', 1, 1),
    ('Neena Nejad and Xoel Pamos', 'Neena Nejad', 1, 1),
    ('Louise Palanker and Bill Filipiak', 'Louise Palanker', 1, 1),
    ('Elan Bogarín & Jonathan Bogarín', 'Elan Bogarín', 1, 1),
    
    -- Second director in compound names
    ('A. V. Meiyappan A. T. Krishnaswamy', 'A.T. Krishnaswamy', 1, 2),
    ('Yogesh Jadhav  Nitin Chavan', 'Nitin Chavan', 1, 2),
    ('Shiboprasad Mukherjee and Nandita Roy', 'Nandita Roy', 1, 2),
    ('Neena Nejad and Xoel Pamos', 'Xoel Pamos', 1, 2),
    ('Louise Palanker and Bill Filipiak', 'Bill Filipiak', 1, 2),
    ('Elan Bogarín & Jonathan Bogarín', 'Jonathan Bogarín', 1, 2);

ALTER TABLE amazonprime_directors
ADD director_cleaned VARCHAR(2048);

UPDATE d
SET director_cleaned = m.director_cleaned
FROM amazonprime_directors d
JOIN director_name_mapping m
ON LTRIM(RTRIM(UPPER(d.director))) = LTRIM(RTRIM(UPPER(m.alias_raw)))
WHERE m.is_compound_name = 0;
        
WITH compound_directors AS (
            SELECT DISTINCT
                d.show_id,
                m.director_cleaned,
                m.canonical_position
            FROM amazonprime_directors d
            JOIN director_name_mapping m
                ON LTRIM(RTRIM(UPPER(d.director))) = LTRIM(RTRIM(UPPER(m.alias_raw)))
            WHERE m.is_compound_name = 1
        )
-- Handle existing compound names (mark them for deletion)
UPDATE d
SET director_cleaned = 'TO_DELETE'
FROM amazonprime_directors d
JOIN director_name_mapping m
ON LTRIM(RTRIM(UPPER(d.director))) = LTRIM(RTRIM(UPPER(m.alias_raw)))
WHERE m.is_compound_name = 1;
        
-- Insert new rows for each director in compound names
WITH compound_directors AS (
            SELECT DISTINCT
                d.show_id,
                m.director_cleaned,
                m.canonical_position
            FROM amazonprime_directors d
            JOIN director_name_mapping m
                ON LTRIM(RTRIM(UPPER(d.director))) = LTRIM(RTRIM(UPPER(m.alias_raw)))
            WHERE m.is_compound_name = 1
        )
INSERT INTO amazonprime_directors (show_id, director, director_cleaned)
SELECT cd.show_id,cd.director_cleaned,cd.director_cleaned
FROM compound_directors cd;
        
-- Delete the original compound name rows
DELETE FROM amazonprime_directors
WHERE director_cleaned = 'TO_DELETE';
        
-- Set default for remaining NULLs - use original value
UPDATE amazonprime_directors
SET director_cleaned = director
WHERE director_cleaned IS NULL;

SELECT * FROM amazonprime_directors
ORDER BY director;


------ Countries
IF OBJECT_ID('amazonprime_countries', 'U') IS NOT NULL
    DROP TABLE amazonprime_countries;

SELECT DISTINCT 
    m.canonical_show_id AS show_id,
    LTRIM(RTRIM(value)) AS country
INTO amazonprime_countries
FROM amazonprime_raw raw
CROSS APPLY STRING_SPLIT(ISNULL(raw.country, 'Unknown'), ',')
JOIN show_id_mapping m ON raw.show_id = m.original_show_id;

SELECT * FROM amazonprime_countries;

SELECT country,COUNT(DISTINCT show_id)
FROM amazonprime_countries
GROUP BY country;


--shows shows with country as null
SELECT *
FROM amazonprime_raw
WHERE country IS NULL;

-------- Creating a mapping for director and country
SELECT director,country
FROM amazonprime_countries ac INNER JOIN amazonprime_directors ad
ON ac.show_id = ad.show_id
GROUP BY director,country;

------ Shows movies/shows listed in diffrent country in raw data
SELECT * FROM amazonprime_raw
WHERE show_id IN (
					SELECT show_id
					FROM amazonprime_countries
					GROUP BY show_id
					HAVING COUNT(*) > 1)
ORDER BY director;


--- inserting rows to fill up country table by director-country mapping
INSERT INTO amazonprime_countries
SELECT show_id,m.country
FROM amazonprime_raw ar
INNER JOIN (SELECT director,country
			FROM amazonprime_countries ac INNER JOIN amazonprime_directors ad
			ON ac.show_id = ad.show_id
			GROUP BY director,country) m
ON ar.director = m.director
WHERE ar.country ='Unknown';



------ Genres

SELECT DISTINCT listed_in
FROM amazonprime_raw
ORDER BY listed_in

-------Creating a diffrent table for genre
IF OBJECT_ID('amazonprime_genre', 'U') IS NOT NULL
    DROP TABLE amazonprime_genre;


SELECT DISTINCT 
    m.canonical_show_id AS show_id,
    LTRIM(RTRIM(value)) AS genre
INTO amazonprime_genre
FROM amazonprime_raw raw
CROSS APPLY STRING_SPLIT(ISNULL(raw.listed_in, 'Unknown'), ',')
JOIN show_id_mapping m ON raw.show_id = m.original_show_id;


SELECT genre,COUNT(*)
FROM amazonprime_genre
GROUP BY genre;

WITH ShowsWithAllThreeGenres AS (
    SELECT show_id 
    FROM amazonprime_genre 
    WHERE genre IN ('Arts','Entertainment','and Culture' ) 
    GROUP BY show_id 
    HAVING COUNT(DISTINCT genre) = 3
)
-- Merge the three genres for these shows
UPDATE ag
SET genre = 'Arts, Entertainment and Culture'
FROM amazonprime_genre ag
JOIN ShowsWithAllThreeGenres s ON ag.show_id = s.show_id
WHERE ag.genre IN ('Arts','Entertainment','and Culture' );

SELECT DISTINCT show_id, genre 
INTO #amazonprime_genre_clean
FROM amazonprime_genre;

-- Delete and repopulate with clean data
DELETE FROM amazonprime_genre;

INSERT INTO amazonprime_genre (show_id, genre)
SELECT show_id, genre FROM #amazonprime_genre_clean;

-- Cleanup
DROP TABLE #amazonprime_genre_clean;


SELECT * FROM amazonprime_genre;


------ Cast Members table


IF OBJECT_ID('amazonprime_cast', 'U') IS NOT NULL
    DROP TABLE amazonprime_cast;


SELECT DISTINCT 
    m.canonical_show_id AS show_id,
    LTRIM(RTRIM(value)) AS cast
INTO amazonprime_cast
FROM amazonprime_raw raw
CROSS APPLY STRING_SPLIT(ISNULL(raw.cast, 'Unknown'), ',')
JOIN show_id_mapping m ON raw.show_id = m.original_show_id;

SELECT * FROM amazonprime_cast;



SELECT cast,COUNT(DISTINCT show_id)
FROM amazonprime_cast
GROUP BY cast;


---Remove quotes (" and ')
UPDATE amazonprime_cast
SET cast = REPLACE(REPLACE(cast,'"',''),'''','');


----Remove leading question marks
UPDATE amazonprime_cast
SET cast = LTRIM(SUBSTRING(cast, PATINDEX('%[^?]%', cast), LEN(cast)))
WHERE cast LIKE '?%';

----Replace junk values like '??????', '?????????'
UPDATE amazonprime_cast
SET cast = 'Unkown'
WHERE cast LIKE '????%' AND LEN(REPLACE(cast,'?','')) = 0;


---replace entries like ·???·??
UPDATE amazonprime_cast
SET cast = 'Unknown'
WHERE cast IS NULL OR
      cast NOT LIKE '%[A-Z0-9]%' -- no alphanumeric content
      AND LEN(cast) > 0;


---Update for blank values
UPDATE amazonprime_cast
SET cast = 'Unknown'
WHERE cast ='';

----Trim any remaining extra spaces
UPDATE amazonprime_cast
SET cast = LTRIM(RTRIM(cast));
