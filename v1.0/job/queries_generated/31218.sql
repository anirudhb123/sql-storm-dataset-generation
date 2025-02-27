WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           0 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
themed_movies AS (
    SELECT mh.movie_id, 
           mh.title, 
           mh.production_year,
           COALESCE(mk.keyword, 'No Keywords') AS themes,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM movie_hierarchy mh
    LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
),
ranked_movies AS (
    SELECT *,
           RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast_count
    FROM themed_movies
)
SELECT t.movie_id,
       t.title,
       t.production_year,
       t.themes,
       t.cast_count,
       CASE
           WHEN rank_by_cast_count <= 5 THEN 'Top Cast'
           ELSE 'Lower Cast'
       END AS cast_rank
FROM ranked_movies t
WHERE t.cast_count IS NOT NULL
  AND t.production_year >= 2000
ORDER BY t.production_year ASC, t.cast_count DESC;

-- Performance benchmarking can be conducted on the above query
-- to analyze execution time and resource consumption.
