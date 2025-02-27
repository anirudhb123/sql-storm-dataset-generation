WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        mt.movie_id,
        mt.movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mt.production_year DESC) AS latest_movie_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title mt ON c.movie_id = mt.id
),
ranked_actors AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.latest_movie_rank,
        COUNT(*) OVER (PARTITION BY am.actor_name) AS movie_count
    FROM actor_movies am
    WHERE am.latest_movie_rank = 1
),
movie_info_aggregated AS (
    SELECT 
        mu.movie_id,
        COUNT(mi.info) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM movie_info mi
    JOIN title mu ON mi.movie_id = mu.id
    GROUP BY mu.movie_id
)

SELECT 
    rh.movie_id,
    rh.movie_title,
    rh.production_year,
    ra.actor_name,
    ra.movie_count,
    mia.info_count,
    mia.info_details
FROM movie_hierarchy rh
LEFT JOIN ranked_actors ra ON ra.movie_title = rh.movie_title
LEFT JOIN movie_info_aggregated mia ON mia.movie_id = rh.movie_id
WHERE rh.level <= 2
AND (ra.movie_count IS NULL OR ra.movie_count > 1)
ORDER BY rh.production_year DESC, ra.movie_count DESC NULLS LAST;
