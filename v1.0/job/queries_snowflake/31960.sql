WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mc.id,
        mc.title,
        mc.production_year,
        mc.kind_id,
        mt.id AS parent_movie_id,
        level + 1
    FROM 
        aka_title mc
    JOIN 
        movie_hierarchy mt ON mc.episode_of_id = mt.id
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
filtered_movies AS (
    SELECT 
        mh.id AS movie_id,
        mh.title,
        mh.production_year,
        ar.distinct_roles,
        ar.avg_order,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ar.distinct_roles DESC, mh.title) AS rn
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actor_roles ar ON mh.id = ar.movie_id
    WHERE 
        mh.production_year IS NOT NULL
        AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(f.distinct_roles, 0) AS distinct_role_count,
    COALESCE(f.avg_order, 0) AS average_order,
    CASE 
        WHEN COALESCE(f.distinct_roles, 0) > 0 THEN 'Has roles' 
        ELSE 'No roles' 
    END AS role_status
FROM 
    filtered_movies f
WHERE 
    f.rn <= 10 
ORDER BY 
    f.production_year DESC, 
    f.distinct_roles DESC;