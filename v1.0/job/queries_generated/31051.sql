WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(t2.title, 'Original') AS parent_title,
        mt.season_nr,
        mt.episode_nr,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title t2 ON mt.episode_of_id = t2.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(t2.title, 'Original') AS parent_title,
        mt.season_nr,
        mt.episode_nr,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'episode')
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.parent_title ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
),
actor_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type c ON ci.role_id = c.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.parent_title,
    rm.level,
    acr.role_count,
    acr.actor_count,
    CASE
        WHEN acr.actor_count IS NULL THEN 'No actors'
        ELSE CONCAT(acr.actor_count, ' actors')
    END AS actor_summary,
    RANK() OVER (ORDER BY rm.production_year DESC) AS production_rank
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_role_counts acr ON rm.movie_id = acr.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.level, rm.production_rank
LIMIT 50;
