WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        CAST(NULL AS text) AS parent_movie_title,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title AS movie_title, 
        at.production_year, 
        mh.movie_title AS parent_movie_title,
        level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title, 
        mh.production_year,
        mh.parent_movie_title,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_within_year
    FROM movie_hierarchy mh
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        mc.total_actors,
        mc.actor_names,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY mc.total_actors DESC) AS actor_rank
    FROM ranked_movies rm
    LEFT JOIN movie_cast mc ON rm.movie_id = mc.movie_id
    WHERE rm.rank_within_year <= 5
)
SELECT 
    fm.movie_title,
    fm.production_year,
    xx.actor_names,
    CASE 
        WHEN fm.total_actors IS NULL THEN 'No actors listed'
        ELSE fm.total_actors::text || ' actors'
    END AS actor_count,
    'Produced in: ' || COALESCE(fm.production_year::text, 'Unknown Year') AS production_comment
FROM filtered_movies fm
LEFT JOIN movie_cast xx ON fm.movie_id = xx.movie_id
WHERE actor_rank IS NOT NULL
ORDER BY fm.production_year DESC, fm.actor_count DESC;
