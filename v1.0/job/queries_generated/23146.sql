WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.production_year, 0) AS production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
   
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        COALESCE(at.production_year, 0) AS production_year,
        at.kind_id,
        mh.level + 1 AS level,
        CAST(mh.full_path || ' -> ' || at.title AS VARCHAR(255)) AS full_path
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5 -- Limit the recursion depth to avoid deep hierarchies
),

filtered_cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.movie_id, ci.person_id
),

movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.role_count,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mc.role_count DESC) AS rn
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        filtered_cast mc ON mh.movie_id = mc.movie_id
)

SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    CASE 
        WHEN mwc.role_count IS NULL THEN 'No Cast'
        WHEN mwc.role_count > 0 THEN 'Has Cast'
        ELSE 'Unknown'
    END AS cast_status,
    mwc.role_count
FROM 
    movies_with_cast mwc
WHERE 
    mwc.rn = 1
AND 
    mwc.role_count IS NOT NULL
ORDER BY 
    mwc.production_year DESC NULLS LAST,
    mwc.title ASC;
