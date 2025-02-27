WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- only top-level movies
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.episode_of_id  -- recursive join to get episodes
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),
title_with_cast AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level,
        mc.actor_count,
        mc.actor_names,
        COALESCE(mt.production_year, 'Unknown') AS production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mc.actor_count DESC) AS rank
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mt.id = mh.movie_id
    LEFT JOIN 
        movie_cast mc ON mc.movie_id = mh.movie_id
)
SELECT 
    twc.movie_id,
    twc.title,
    twc.production_year,
    twc.actor_count,
    twc.actor_names,
    CASE 
        WHEN twc.rank = 1 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS category
FROM 
    title_with_cast twc
WHERE 
    twc.actor_count IS NOT NULL
    AND twc.level = 1  -- Filter for only main movies (excluding episodes)
ORDER BY 
    twc.actor_count DESC
LIMIT 10;
