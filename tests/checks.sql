/*
=======================================================
This file is just for checking all the transformations.
=======================================================
*/

SELECT * 
FROM amazonprime_raw;

SELECT COUNT(*) 
FROM amazonprime_raw;

----- Checking for any foreign charactrers in the title
SELECT show_id,title
FROM amazonprime_raw
ORDER BY title;

DELETE FROM amazonprime_raw
WHERE director = 'Clip: Validation Check CAPI'

--------------- Checking columns

SELECT rating,COUNT(*)
FROM amazonprime_raw
GROUP BY rating;

SELECT * FROM amazonprime_raw
WHERE rating IN ('AGES_18','NOT_RATE','ALL_AGES')

SELECT duration,COUNT(*)
FROM amazonprime_raw
GROUP BY duration;

SELECT release_year,COUNT(*)
FROM amazonprime_raw
GROUP BY release_year;


SELECT director
FROM amazonprime_raw
ORDER BY director;

DELETE FROM amazonprime_raw
WHERE director IN ('???','????', '1', '20th Century Fox', '9 state Entertainment','20th_century_fox','9 Story Entertainment');

----------removing dupplicates

---- checking duplicates id's
SELECT show_id,COUNT(*)
FROM amazonprime_raw
GROUP BY show_id
HAVING COUNT(*) > 1;


-------checking duplicate shows

SELECT UPPER(title),type,COUNT(*)
FROM amazonprime_raw
GROUP BY UPPER(title),type
HAVING COUNT(*) > 1;

SELECT * FROM amazonprime_raw
WHERE CONCAT(UPPER(title),type) IN (SELECT CONCAT(UPPER(title),type)
				FROM amazonprime_raw
				GROUP BY UPPER(title),type
				HAVING COUNT(*) > 1)
ORDER BY title


----------Removing Duplicates

WITH cte AS (
SELECT *,ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) as rn
FROM amazonprime_raw)

SELECT *
FROM cte
WHERE rn=1




--- Datatype Conversion for date_added
--- Populate Missing values for country,duration columns
--- Ppulate rest of nulls as Not_available
--- Drop columns: director, listed_in,country,cast

WITH cte AS (
SELECT *,ROW_NUMBER() OVER(PARTITION BY title,type ORDER BY show_id) as rn
FROM amazonprime_raw)

SELECT show_id,type,title,CAST(date_added AS date) AS date_added,release_year,rating,duration,description
FROM cte
WHERE rn=1



--- Populate Missing values for country column

--shows shows with country as null
SELECT *
FROM amazonprime_raw
WHERE country IS NULL;

---checking if director has made other movies/shows which has country column filled
SELECT *
FROM amazonprime_raw
WHERE director = 'Habib Azar'


-------- Creating a mapping for director and country
SELECT director,country
FROM amazonprime_countries ac INNER JOIN amazonprime_directors ad
ON ac.show_id = ad.show_id
GROUP BY director,country

------ Shows movies/shows listed in diffrent country in raw data
SELECT * FROM amazonprime_raw
WHERE show_id IN (
					SELECT show_id
					FROM amazonprime_countries
					GROUP BY show_id
					HAVING COUNT(*) > 1)
ORDER BY director;



--- inserting rows to fill up country table by director-country mapping
INSERT INTO amazonprime_country
SELECT show_id,m.country
FROM amazonprime_raw ar
INNER JOIN (SELECT director,country
			FROM amazonprime_country ac INNER JOIN amazonprime_directors ad
			ON ac.show_id = ad.show_id
			GROUP BY director,country) m
ON ar.director = m.director
WHERE ar.country IS NULL;


SELECT show_id,title
FROM amazonprime_raw
WHERE UPPER(title) Like 'SAAHO%';


----Fixing rating column
SELECT show_id,type,title,rating,LTRIM(RTRIM(CASE WHEN CHARINDEX('(',title) > 0 THEN LEFT(title,CHARINDEX('(',title)-1) ELSE title END)) AS base_title,
CASE WHEN rating IN ('ALL','G','ALL_AGES','TV-Y','TV-G') THEN 'All Ages'
	 WHEN rating IN ('7+','TV-Y7') THEN 'Kids 7+'
	 WHEN rating IN ('PG-13','TV-PG','TV-14','13+') THEN 'Teens 13+'
	 WHEN rating IN ('16+','16','AGES_16_') THEN 'Teens 16+'
	 WHEN rating IN ('R','TV-MA','18+','AGES_18_','NC-17') THEN 'Adults 18+'
	 WHEN rating IN ('PG','TV-PG') THEN 'Parental Guide'
	 WHEN rating IN ('NR','TV-NR','UNRATED','NOT_RATE') OR rating IS NULL THEN 'Not Rated'
END AS new_rating,release_year,duration,description
FROM amazonprime_raw;





SELECT * FROM amazonprime_raw
WHERE show_id ='S8912';



SELECT * FROM amazonprime_raw
WHERE show_id ='s8972';

SELECT * FROM amazonprime_raw
WHERE title LIKE 'Act%'

SELECT DISTINCT director FROM amazonprime_raw
ORDER BY director


SELECT * FROM amazonprime_raw
WHERE show_id IN (	SELECT DISTINCT show_id FROM amazonprime_cast
					WHERE cast IN ('1','2','3','A','20TH_CENTURY_FOX','3Run Parkour')
);

SELECT DISTINCT show_id FROM amazonprime_cast
WHERE cast IN ('1','2','3','A','20TH_CENTURY_FOX','3Run Parkour')
;

SELECT DISTINCT duration
FROM amazonprime_raw
ORDER BY duration;

SELECT * FROM amazonprime_raw
WHERE director = 'A. V. Meiyappan A. T. Krishnaswamy' OR director IN ('AK.REED FILMS (Amire K Reed)','AK. Reed Films (Amire k reed)','AK. Reed Films  (Amire k reed)')



--------
SELECT 
    director_key, 
    COUNT(*) AS count,
    STRING_AGG(DISTINCT director, ',') AS variants
FROM amazonprime_directors
GROUP BY director_key
ORDER BY count DESC;



SELECT * FROM amazonprime_raw
WHERE director LIKE 'T%'
ORDER BY director


SELECT * FROM amazonprime_raw
WHERE director LIKE '%Reddy%';


SELECT DISTINCT duration
FROM amazonprime_raw;

----Fixing rating column
SELECT show_id,type,title,rating,LTRIM(RTRIM(CASE WHEN CHARINDEX('(',title) > 0 THEN LEFT(title,CHARINDEX('(',title)-1) ELSE title END)) AS base_title,
CASE WHEN rating IN ('ALL','G','ALL_AGES','TV-Y','TV-G') THEN 'All Ages'
	 WHEN rating IN ('7+','TV-Y7') THEN 'Kids 7+'
	 WHEN rating IN ('PG-13','TV-PG','TV-14','13+') THEN 'Teens 13+'
	 WHEN rating IN ('16+','16','AGES_16_') THEN 'Teens 16+'
	 WHEN rating IN ('R','TV-MA','18+','AGES_18_','NC-17') THEN 'Adults 18+'
	 WHEN rating IN ('PG','TV-PG') THEN 'Parental Guide'
	 WHEN rating IN ('NR','TV-NR','UNRATED','NOT_RATE') OR rating IS NULL THEN 'Not Rated'
END AS new_rating,release_year,duration,description
FROM amazonprime_raw;


SELECT * FROM amazonprime_cast





SELECT * FROM amazonprime_raw
WHERE UPPER(title) IN ( 
SELECT UPPER(title)
FROM amazonprime_raw
GROUP BY UPPER(title),type
HAVING COUNT(*) > 1);

-----list of directors who directed both movies ans shows
SELECT *
FROM amazonprime_raw
WHERE director LIKE '%D.J. Viola%'


SELECT *
FROM amazonprime_shows_cleaned s
WHERE s.type = 'TV SHOW'AND rating_cleaned LIKE 'Pa%';
