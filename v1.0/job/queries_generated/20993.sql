WITH RecursiveActorAge AS (
    SELECT ak.person_id,
           ak.name,
           COUNT(DISTINCT ci.movie_id) AS movie_count,
           AVG(YEAR(CURRENT_DATE) - ti.production_year) AS avg_age
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title ti ON ci.movie_id = ti.movie_id
    WHERE ti.production_year IS NOT NULL
    GROUP BY ak.person_id, ak.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
),
CTEMovies AS (
    SELECT mt.title,
           mt.production_year,
           mt.id AS movie_id,
           ak.name AS actor_name,
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS row_num
    FROM aka_title mt
    JOIN cast_info ci ON mt.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE mt.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
),
DetailedStats AS (
    SELECT r.actor_name,
           r.movie_count,
           r.avg_age,
           c.name AS company_name,
           COUNT(DISTINCT ci.movie_id) AS total_films
    FROM RecursiveActorAge r
    LEFT JOIN movie_companies mc ON r.movie_count = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN cast_info ci ON r.person_id = ci.person_id
    GROUP BY r.actor_name, r.movie_count, r.avg_age, c.name
)
SELECT ds.actor_name,
       ds.movie_count,
       ds.avg_age,
       COALESCE(ds.company_name, 'Independent') AS company,
       STRING_AGG(DISTINCT mt.title, ', ') FILTER (WHERE mt.row_num <= 3) AS top_movies,
       CASE 
           WHEN ds.total_films > 10 THEN 'Prolific'
           WHEN ds.total_films BETWEEN 5 AND 10 THEN 'Emerging'
           ELSE 'Newcomer'
       END AS status
FROM DetailedStats ds
JOIN CTEMovies mt ON ds.actor_name = mt.actor_name
GROUP BY ds.actor_name, ds.movie_count, ds.avg_age, ds.company_name
ORDER BY ds.movie_count DESC, ds.avg_age DESC
LIMIT 50;
