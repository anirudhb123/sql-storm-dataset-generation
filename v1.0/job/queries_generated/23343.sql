WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastAgg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS total_cast,
           STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
MoviesWithGenres AS (
    SELECT mt.id AS movie_id,
           mt.title,
           STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    JOIN keyword kt ON mk.keyword_id = kt.id
    GROUP BY mt.id
),
PerformanceMetrics AS (
    SELECT mh.movie_id,
           mh.title,
           mh.production_year,
           ca.total_cast,
           mw.genres,
           EXTRACT(YEAR FROM AGE(NOW(), mh.production_year::date)) AS age_in_years,
           CASE 
               WHEN ca.total_cast > 10 THEN 'Large Cast'
               WHEN ca.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
               ELSE 'Small Cast'
           END AS cast_size
    FROM MovieHierarchy mh
    LEFT JOIN CastAgg ca ON mh.movie_id = ca.movie_id
    LEFT JOIN MoviesWithGenres mw ON mh.movie_id = mw.movie_id
)
SELECT pm.title,
       pm.production_year,
       pm.total_cast,
       pm.genres,
       pm.age_in_years,
       pm.cast_size
FROM PerformanceMetrics pm
WHERE (pm.age_in_years > 15 OR pm.genres LIKE '%Drama%')
  AND pm.page IS NULL  -- Assuming a hypothetical column for pagination
ORDER BY pm.production_year DESC, pm.total_cast DESC
LIMIT 50;

-- This query retrieves films made from the year 2000 onwards, along with their cast details, 
-- genre information, and calculates the age of each movie. It categorizes movies 
-- based on the size of their cast and filters for older movies or those belonging to the Drama genre.
