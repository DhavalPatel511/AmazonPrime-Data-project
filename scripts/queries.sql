/*
=============================
Some of  the questions solved after the final data processing.
=============================
*/

----Q1.For each director, count the number of movies and TV shows they've directed, but only include those who have directed both types.

SELECT d.director_cleaned,
       COUNT(DISTINCT s.type) AS type_count,
       SUM(CASE WHEN s.type = 'MOVIE' THEN 1 ELSE 0 END) AS num_movies,
       SUM(CASE WHEN s.type = 'TV SHOW' THEN 1 ELSE 0 END) AS num_tv_shows
FROM amazonprime_directors d
JOIN view_amazonprime_summary s ON d.show_id = s.show_id
GROUP BY d.director_cleaned
HAVING COUNT(DISTINCT s.type) = 2;

----Q2.Which country has the highest number of Comedy or Action movies? Display separate counts for each genre per country.


SELECT c.country,COUNT(CASE WHEN g.genre = 'Comedy' AND s.type = 'MOVIE' THEN 1 END) AS comedy_movies,COUNT(CASE WHEN g.genre = 'Action' AND s.type = 'MOVIE' THEN 1 END) AS action_movies
FROM amazonprime_shows_cleaned s
JOIN amazonprime_countries c ON s.show_id = c.show_id
JOIN amazonprime_genre g ON s.show_id = g.show_id
GROUP BY c.country
HAVING COUNT(CASE WHEN g.genre IN ('Comedy','Action') AND s.type = 'MOVIE' THEN 1 END) > 0
ORDER BY comedy_movies DESC ,action_movies DESC;


----Q3.Which director released the maximum number of movies in each year?
WITH cte AS (
SELECT
	release_year,
	d.director_cleaned as director,
	COUNT(*)  as no_of_movies
FROM amazonprime_shows_cleaned s
JOIN amazonprime_directors d ON d.show_id = s.show_id
WHERE s.type = 'MOVIE'
GROUP BY  release_year,d.director_cleaned)
SELECT * 
FROM (
SELECT 
	release_year,
	director,
	no_of_movies,
	DENSE_RANK() OVER(PARTITION BY release_year ORDER BY no_of_movies DESC) AS rnk
FROM cte) ranked
WHERE rnk=1;


----Q4.What is the average duration of movies in each genre?

SELECT g.genre,AVG(CAST(duration_minutes AS DECIMAL)) AS avg_duration_mins
FROM amazonprime_shows_cleaned s
JOIN amazonprime_genre g ON s.show_id = g.show_id
WHERE s.type = 'MOVIE' AND  s.duration_minutes IS NOT NULL
GROUP BY g.genre
ORDER BY avg_duration_mins;


----Q5.List directors who have created both Horror and Comedy movies. Display director name, and count of each genre.
SELECT *
FROM
(SELECT d.director_cleaned,COUNT(CASE WHEN g.genre='Horror' AND s.type='MOVIE' THEN 1 ELSE NULL END) AS horror_movies,COUNT(CASE WHEN g.genre='Comedy' AND s.type='MOVIE' THEN 1 ELSE NULL END) AS comedy_movies
FROM amazonprime_shows_cleaned s
JOIN amazonprime_genre g ON s.show_id = g.show_id
JOIN amazonprime_directors d ON d.show_id = s.show_id
GROUP BY d.director_cleaned) counts
WHERE horror_movies > 0 AND comedy_movies > 0
ORDER BY horror_movies DESC,comedy_movies DESC ;

----Q6.Which cast member has appeared in the most number of unique titles? Also show their top 3 genres (if available).

WITH most_appeared AS (
SELECT  TOP 1 c.cast,COUNT(DISTINCT s.base_title) as unique_titles
FROM amazonprime_shows_cleaned s
JOIN amazonprime_cast c ON s.show_id = c.show_id
WHERE c.cast <> 'Unknown'
GROUP BY c.cast
ORDER BY unique_titles DESC),
top_genres AS 
(SELECT c.cast,g.genre,COUNT(DISTINCT s.base_title) as no_of_movies,DENSE_RANK() OVER(PARTITION BY c.cast ORDER BY COUNT(DISTINCT s.base_title) DESC) AS rnk
FROM amazonprime_shows_cleaned s
JOIN amazonprime_cast c ON s.show_id = c.show_id
JOIN amazonprime_genre g ON s.show_id = g.show_id
WHERE c.cast = (SELECT cast FROM most_appeared)
GROUP BY c.cast,g.genre )

SELECT cast,genre,no_of_movies
FROM top_genres
WHERE rnk <= 3;

----Q7.For each genre, what is the trend of new content added over the years? (Based on release_year)

WITH genre_year_counts AS (
SELECT g.genre,
		s.release_year,
		COUNT(s.show_id) AS  no_of_content
FROM amazonprime_shows_cleaned s
JOIN amazonprime_genre g ON s.show_id = g.show_id
WHERE s.release_year IS NOT NULL
GROUP BY g.genre,s.release_year
)

SELECT  genre,
		release_year,
		no_of_content,
		LAG(no_of_content) OVER (PARTITION BY genre ORDER BY release_year) as previous_year_count,
		no_of_content - LAG(no_of_content) OVER (PARTITION BY genre ORDER BY release_year) as change_from_prev_year
FROM genre_year_counts
ORDER BY genre,release_year;




----Q8.List the top 10 most frequent director–cast combinations (pairs) and how many titles they collaborated on.

SELECT TOP 10
    d.director_cleaned,
    c.cast,
    COUNT(DISTINCT d.show_id) AS titles_together
FROM amazonprime_directors d
JOIN amazonprime_cast c ON d.show_id = c.show_id
WHERE d.director_cleaned <> 'Unknown' AND c.cast <> 'Unknown'
GROUP BY d.director_cleaned, c.cast
ORDER BY titles_together DESC;

----Q9.Which genres tend to have the longest average durations? Include min, avg, and max duration in minutes.

SELECT g.genre,MIN(CAST(duration_minutes AS DECIMAL)) AS min_duration_mins,AVG(CAST(duration_minutes AS DECIMAL)) AS avg_duration_mins,MAX(CAST(duration_minutes AS DECIMAL)) AS max_duration_mins
FROM amazonprime_shows_cleaned s
JOIN amazonprime_genre g ON s.show_id = g.show_id
WHERE s.type = 'MOVIE' AND s.duration_minutes IS NOT NULL
GROUP BY g.genre
ORDER BY avg_duration_mins DESC;

----Q10.Which countries produced the most TV Shows with more than 3 seasons?

SELECT c.country,COUNT(DISTINCT s.show_id) as no_of_tv_shows
FROM amazonprime_shows_cleaned s
JOIN amazonprime_countries c ON s.show_id = c.show_id
WHERE s.type = 'TV SHOW' AND s.duration_seasons > 3 AND c.country <> 'Unknown'
GROUP BY c.country
ORDER BY  no_of_tv_shows DESC;


----Q11.What percentage of all movies fall into each duration_bucket?

WITH tot AS (
SELECT COUNT(DISTINCT base_title) as total_movies
FROM amazonprime_shows_cleaned
WHERE type= 'MOVIE'
)
SELECT duration_bucket,COUNT(DISTINCT base_title) as no_of_movies,
	ROUND(COUNT(DISTINCT base_title)*100.0 /(SELECT total_movies FROM tot),2) AS percent_split
FROM amazonprime_shows_cleaned s
WHERE s.type ='MOVIE'
GROUP BY duration_bucket;


----Q12.Which rating categories are most common in TV Shows vs. Movies?

SELECT rating_cleaned,COUNT(CASE WHEN type='MOVIE' THEN 1 END) AS movies,COUNT(CASE WHEN type='TV SHOW' THEN 1 END) AS tv_shows,
FROM amazonprime_shows_cleaned
GROUP BY rating_cleaned;
