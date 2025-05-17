/*
=====================================
Create final tables and views for further reporting and ad-hoc queries
=====================================
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






------------ Creating view for further analysis and reporting
------The exploded view (vw_amazonprime_full) for detailed analysis

IF OBJECT_ID('view_amazonprime', 'V') IS NOT NULL
    DROP VIEW view_amazonprime;
GO


CREATE VIEW view_amazonprime AS
SELECT 
    s.show_id,
    s.title,
	s.base_title,
    s.type,
    s.release_year,
    s.rating_cleaned AS show_rating,
    s.duration_minutes,
	s.duration_bucket,
	s.duration_seasons,
    s.description,
    COALESCE(d.director_cleaned,d.director) AS director,
    c.cast,
    cn.country,
    g.genre
FROM amazonprime_shows_cleaned s
LEFT JOIN amazonprime_directors d ON s.show_id = d.show_id
LEFT JOIN amazonprime_cast c ON s.show_id = c.show_id
LEFT JOIN amazonprime_countries cn ON s.show_id = cn.show_id
LEFT JOIN amazonprime_genre g ON s.show_id = g.show_id;


SELECT * FROM view_amazonprime;

-----A flattened view (vw_amazonprime_summary) for dashboards and top-level insights
IF OBJECT_ID('view_amazonprime_summary', 'V') IS NOT NULL
    DROP VIEW view_amazonprime_summary;
GO

CREATE VIEW view_amazonprime_summary AS
SELECT 
    s.show_id,
    s.title,
	s.base_title,
    s.type,
    s.release_year,
    s.rating_cleaned AS show_rating,
    s.duration_minutes,
	s.duration_bucket,
	s.duration_seasons,
    s.description,
	 -- Aggregate genres with DISTINCT
    (SELECT STRING_AGG(genre, ', ') 
     FROM (SELECT DISTINCT g.genre, g.show_id 
           FROM amazonprime_genre g 
           WHERE g.show_id = s.show_id) AS subg) AS genres,
    -- Aggregate directors with DISTINCT
    (SELECT STRING_AGG(director, ', ') 
     FROM (SELECT DISTINCT COALESCE(d.director_cleaned,d.director) AS director, d.show_id 
           FROM amazonprime_directors d 
           WHERE d.show_id = s.show_id) AS subd) AS directors,
    -- Aggregate cast with DISTINCT
    (SELECT STRING_AGG(cast, ', ') 
     FROM (SELECT DISTINCT c.cast, c.show_id 
           FROM amazonprime_cast c 
           WHERE c.show_id = s.show_id) AS subc) AS cast_members,
    -- Aggregate countries with DISTINCT
    (SELECT STRING_AGG(country, ', ') 
     FROM (SELECT DISTINCT cn.country, cn.show_id 
           FROM amazonprime_countries cn 
           WHERE cn.show_id = s.show_id) AS subco) AS countries
FROM amazonprime_shows_cleaned s;

SELECT * FROM view_amazonprime_summary;
-----------------------------------------------
