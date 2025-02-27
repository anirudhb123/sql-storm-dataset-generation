WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.level + 1 AS level,
        CAST(CONCAT(mh.path, ' -> ', at.title) AS VARCHAR(255)) AS path
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5 -- limit depth to avoid excessive recursion
),
actor_count AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info AS ci
    GROUP BY 
        ci.movie_id
),
title_info AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(ac.num_actors, 0) AS actor_count,
        CASE 
            WHEN ac.num_actors IS NULL THEN 'Unknown'
            WHEN ac.num_actors = 0 THEN 'No Actors'
            ELSE 'Has Actors'
        END AS actor_status
    FROM 
        aka_title AS at
    LEFT JOIN 
        actor_count AS ac ON at.id = ac.movie_id
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ti.movie_id,
    ti.title,
    ti.production_year,
    ti.actor_count,
    ti.actor_status,
    ki.keywords,
    COALESCE(mh.path, 'No links') AS hierarchy_path
FROM 
    title_info AS ti
LEFT JOIN 
    keyword_info AS ki ON ti.movie_id = ki.movie_id
LEFT JOIN 
    movie_hierarchy AS mh ON ti.movie_id = mh.movie_id
WHERE 
    ti.production_year IN (SELECT DISTINCT production_year FROM title_info WHERE actor_count > 0)
ORDER BY 
    ti.production_year DESC, 
    ti.actor_count DESC
LIMIT 100;
