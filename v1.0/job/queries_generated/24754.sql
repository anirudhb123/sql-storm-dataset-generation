WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown Year') AS year_info
    FROM title t
    WHERE t.production_year IS NOT NULL OR t.kind_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        CONCAT(t.title, ' Part ', r.title_id) AS title,
        t.production_year,
        t.kind_id,
        r.year_info
    FROM title t
    JOIN RecursiveTitle r ON r.title_id = t.episode_of_id
), 
JoinedInfo AS (
    SELECT 
        ak.name AS actor_name,
        mk.keyword AS movie_keyword,
        ti.title,
        ti.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ti.production_year DESC) AS year_rank
    FROM aka_name ak 
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title ti ON ci.movie_id = ti.movie_id
    LEFT JOIN movie_keyword mk ON ti.id = mk.movie_id
    WHERE ak.name IS NOT NULL AND ti.production_year IS NOT NULL
), 
FilteredInfo AS (
    SELECT 
        ji.actor_name, 
        ji.movie_keyword,
        ji.title,
        ji.production_year,
        ji.year_rank,
        COUNT(*) OVER (PARTITION BY ji.actor_name) AS total_movies
    FROM JoinedInfo ji
    WHERE ji.movie_keyword IS NOT NULL 
      AND ji.year_rank <= 3
)
SELECT 
    actor_name,
    STRING_AGG(title, ', ') AS titles,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    MAX(production_year) AS last_movie_year,
    SUM(NULLIF(year_rank, 0)) AS total_rank_sum,
    MIN(total_movies) AS min_movies_per_actor 
FROM FilteredInfo
GROUP BY actor_name
HAVING COUNT(*) > 1 
   AND MAX(last_movie_year) > CURRENT_DATE - INTERVAL '5 years'
ORDER BY min_movies_per_actor DESC, actor_name;
