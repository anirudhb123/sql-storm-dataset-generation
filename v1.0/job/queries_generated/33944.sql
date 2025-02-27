WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to get all movies with their parent episodes (if any)
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.episode_of_id,
        mh.depth + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
-- CTE to gather detailed info about cast and their roles
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
-- CTE to aggregate movie information
movie_overview AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.actor_name) AS total_cast,
        MAX(cd.actor_rank) AS highest_ranked_actor,
        STRING_AGG(cd.actor_name, ', ') AS actor_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
-- Final selection with filtering and sorting
SELECT 
    mo.movie_id,
    mo.title,
    mo.production_year,
    mo.total_cast,
    mo.highest_ranked_actor,
    mo.actor_list,
    CASE 
        WHEN mo.production_year < 2000 THEN 'Classic'
        WHEN mo.production_year >= 2000 AND mo.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_label
FROM 
    movie_overview mo
WHERE 
    mo.total_cast > 5
ORDER BY 
    mo.production_year DESC,
    mo.total_cast DESC;
