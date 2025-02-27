WITH Recursive_Actors AS (
    SELECT a.id as actor_id, a.person_id, a.name, COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN complete_cast cc ON ci.movie_id = cc.movie_id
    WHERE a.name IS NOT NULL
    GROUP BY a.id, a.person_id, a.name
    HAVING COUNT(DISTINCT cc.movie_id) > (SELECT AVG(movie_count) FROM (
        SELECT COUNT(DISTINCT movie_id) AS movie_count
        FROM cast_info
        GROUP BY person_id
    ) AS subquery)
),

Popular_Titles AS (
    SELECT at.id AS title_id, at.title, COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    WHERE at.production_year >= 2000
    GROUP BY at.id, at.title
    HAVING COUNT(DISTINCT ci.person_id) > 10
),

Top_Cast AS (
    SELECT r.actor_id, r.name, ra.movie_id, at.title
    FROM Recursive_Actors r
    JOIN cast_info ci ON r.person_id = ci.person_id
    JOIN complete_cast ra ON ci.movie_id = ra.movie_id
    JOIN aka_title at ON ra.movie_id = at.movie_id
)

SELECT r.actor_id, r.name, at.title, 
       ROW_NUMBER() OVER (PARTITION BY r.actor_id ORDER BY at.title) AS title_row,
       COALESCE(NULLIF(UPPER(at.title), ''), 'NO TITLE') AS title_display,
       CASE 
           WHEN at.title LIKE '% sequel' THEN 'Sequel'
           WHEN at.title LIKE '% remake' THEN 'Remake'
           ELSE 'Original'
       END AS title_type
FROM Top_Cast as r
JOIN Popular_Titles at ON r.title = at.title
WHERE r.movie_id IS NOT NULL
ORDER BY r.actor_id, title_row;

-- This query includes:
-- CTEs for recursive actor information and popular titles
-- LEFT JOINs to connect several tables
-- A correlated subquery within the HAVING clause
-- Window functions to rank titles per actor
-- COALESCE and NULLIF for handling string values
-- CASE statements to classify the title types
