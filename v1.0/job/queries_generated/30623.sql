WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select top-level movies
    SELECT mt.id AS movie_id, mt.title, 1 AS level, mt.production_year
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursive case: select episodes associated with movies
    SELECT at.id AS movie_id, at.title, mh.level + 1, at.production_year
    FROM aka_title at
    JOIN movie_hierarchy mh ON at.episode_of_id = mh.movie_id
),
cast_roles AS (
    -- CTE to aggregate roles for each person in the cast
    SELECT ci.person_id, ci.movie_id, COUNT(ci.role_id) AS role_count
    FROM cast_info ci
    GROUP BY ci.person_id, ci.movie_id
),
distinct_keywords AS (
    -- CTE to select distinct keywords associated with movies
    SELECT mk.movie_id, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movies_with_keywords AS (
    -- Join movies with their keywords
    SELECT mh.movie_id, mh.title, mh.production_year, dk.keywords
    FROM movie_hierarchy mh
    LEFT JOIN distinct_keywords dk ON mh.movie_id = dk.movie_id
),
ranking_movies AS (
    -- Window function to rank movies by production year and level
    SELECT mwk.*, 
           RANK() OVER (PARTITION BY mwk.production_year ORDER BY mwk.level) AS year_rank
    FROM movies_with_keywords mwk
)
-- Final select to benchmark performance
SELECT m.movie_id, 
       m.title, 
       m.production_year, 
       COALESCE(kw.keywords, 'No Keywords') AS keywords,
       COALESCE(cr.role_count, 0) AS total_roles,
       CASE 
           WHEN m.production_year IS NULL THEN 'Unknown Year'
           WHEN m.production_year < 2000 THEN 'Classic'
           ELSE 'Modern'
       END AS era
FROM ranking_movies m
LEFT JOIN cast_roles cr ON m.movie_id = cr.movie_id
ORDER BY m.production_year DESC, m.level ASC;
