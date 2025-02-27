WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           NULL::integer AS parent_id
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id AS movie_id, 
           m.title,
           m.production_year,
           mh.movie_id AS parent_id
    FROM aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN movie_link ml2 ON ml.linked_movie_id = ml2.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE m.production_year IS NOT NULL
)
, ranked_movies AS (
    SELECT mh.movie_id,
           mh.title, 
           mh.production_year,
           ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn,
           COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies
    FROM movie_hierarchy mh
)
, actor_movies AS (
    SELECT ka.person_id,
           ka.name,
           km.movie_id,
           kt.title,
           COUNT(*) OVER (PARTITION BY ka.person_id) AS movie_count,
           ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY kt.production_year DESC) AS recent_movie_rank
    FROM aka_name ka
    JOIN cast_info ci ON ci.person_id = ka.person_id
    JOIN aka_title kt ON kt.id = ci.movie_id
    JOIN ranked_movies km ON km.movie_id = ci.movie_id
)
SELECT am.name AS actor_name,
       am.movie_count,
       COALESCE(STRING_AGG(DISTINCT kt.title ORDER BY kt.production_year), 'No Movies') AS movies,
       CASE 
           WHEN am.recent_movie_rank = 1 THEN 'Latest Movie'
           ELSE 'Not Latest'
       END AS movie_status,
       (SELECT COUNT(*) 
        FROM aka_title 
        WHERE production_year BETWEEN 1990 AND 2000) AS movie_count_90s,
       (SELECT COUNT(*) 
        FROM movie_info mi 
        WHERE mi.note IS NULL) AS info_null_count
FROM actor_movies am
LEFT JOIN aka_title kt ON kt.id = am.movie_id
WHERE am.movie_count > 5
GROUP BY am.name, am.movie_count, am.recent_movie_rank
HAVING COUNT(DISTINCT kt.title) > 3
ORDER BY am.movie_count DESC, actor_name
LIMIT 10;


This query aims to illustrate complex SQL features, including recursive common table expressions (CTEs), window functions, COALESCE for NULL handling, and aggregate functions across joined data to extract valuable insights from the given schema. The query benchmarks movie data while capturing relationships between actors and their films, incorporating several characterizations of the resulting dataset.
