WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           mt.kind_id,
           0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           m.kind_id,
           mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
    WHERE mh.level < 5 -- limiting the hierarchy depth
),

cast_aggregates AS (
    SELECT ci.movie_id,
           ARRAY_AGG(DISTINCT a.name) AS actor_names,
           COUNT(ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),

movie_info_aggregates AS (
    SELECT mi.movie_id,
           STRING_AGG(DISTINCT CASE WHEN it.info = 'Summary' THEN mi.info END, '; ') AS summary_info,
           STRING_AGG(DISTINCT CASE WHEN it.info = 'Genre' THEN mi.info END, ', ') AS genre_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
),

movie_details AS (
    SELECT mh.movie_id,
           mh.title,
           CAST(mh.production_year AS TEXT) AS formatted_year,
           COALESCE(mia.actor_names, ARRAY[]::TEXT[]) AS actor_names,
           COALESCE(mia.actor_count, 0) AS actor_count,
           COALESCE(mia.summary_info, 'N/A') AS summary_info,
           COALESCE(mia.genre_info, 'N/A') AS genre_info
    FROM movie_hierarchy mh
    LEFT JOIN cast_aggregates mia ON mh.movie_id = mia.movie_id
), 

ranked_movies AS (
    SELECT md.*,
           ROW_NUMBER() OVER (PARTITION BY md.formatted_year ORDER BY md.actor_count DESC) AS year_rank
    FROM movie_details md
)

SELECT *
FROM ranked_movies
WHERE year_rank <= 3
AND actor_count > 1
ORDER BY production_year DESC, actor_count DESC;

