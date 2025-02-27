WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lat.title,
        lat.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lat ON ml.linked_movie_id = lat.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

cast_with_roles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),

movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No description available') AS description,
        MAX(m.production_year) AS year
    FROM 
       aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    GROUP BY 
        m.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cwr.actor_name) AS total_actors,
    STRING_AGG(DISTINCT cwr.role, ', ') AS roles,
    COALESCE(mis.description, 'N/A') AS movie_description,
    COALESCE(CAST(AVG(cwr.total_cast) AS NUMERIC), 0) AS avg_cast_per_movie
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mis.description
HAVING 
    COUNT(DISTINCT cwr.actor_name) > 1 AND 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC;
