WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cast_info.person_id, 0) AS actor_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ON m.id = cast_info.movie_id
    LEFT JOIN 
        aka_name a ON cast_info.person_id = a.person_id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(mc.linked_actor_id, 0),
        COALESCE(ak.name, 'Unknown') AS actor_name,
        mh.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        cast_info mc ON ml.linked_movie_id = mc.movie_id
    LEFT JOIN 
        aka_name ak ON mc.person_id = ak.person_id
    WHERE 
        mh.level < 5
),

actor_counts AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_hierarchy
    GROUP BY 
        actor_id
),

ranked_actors AS (
    SELECT 
        actor_id,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        actor_counts
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT mh.actor_id) AS total_actors,
    SUM(CASE WHEN ra.actor_id IS NOT NULL THEN 1 ELSE 0 END) AS ranked_actors_count,
    STRING_AGG(DISTINCT mh.actor_name, ', ') AS actors_list
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_actors ra ON mh.actor_id = ra.actor_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mh.actor_id) > 5
ORDER BY 
    total_actors DESC, mh.production_year DESC;
