WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        p.title AS parent_title,
        h.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy h ON e.episode_of_id = h.movie_id
    JOIN 
        aka_title p ON h.movie_id = p.id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.person_role_id IS NOT NULL
    GROUP BY 
        ci.movie_id
),
title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(mh.level, 0) AS hierarchy_level,
        COALESCE(cd.total_actors, 0) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COALESCE(cd.total_actors, 0) DESC) AS ranking,
        CASE 
            WHEN t.production_year < 2000 THEN 'Classic'
            WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        aka_title t
    LEFT JOIN 
        movie_hierarchy mh ON t.id = mh.movie_id
    LEFT JOIN 
        cast_details cd ON t.id = cd.movie_id
)
SELECT 
    ti.title_id,
    ti.title,
    ti.hierarchy_level,
    ti.actor_count,
    ti.ranking,
    ti.era,
    COALESCE(cv.additional_info, 'N/A') AS additional_info
FROM 
    title_info ti
LEFT JOIN (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS additional_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
) cv ON ti.title_id = cv.movie_id
WHERE 
    (ti.actor_count > 2 OR ti.hierarchy_level = 0)
    AND (ti.era = 'Recent' OR ti.era = 'Modern')
ORDER BY 
    ti.hierarchy_level,
    ti.ranking NULLS LAST
LIMIT 100;
