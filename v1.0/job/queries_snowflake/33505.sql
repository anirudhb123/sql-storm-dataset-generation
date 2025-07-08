
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON m.episode_of_id = mh.movie_id
),

cast_aggregated AS (
    SELECT 
        ci.movie_id,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(ci.id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),

info_aggregated AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT it.info || ': ' || mi.info, '; ') WITHIN GROUP (ORDER BY it.info) AS movie_infos
    FROM 
        movie_info mi
    JOIN 
        info_type it ON it.id = mi.info_type_id
    GROUP BY 
        mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    ca.cast_names,
    ca.cast_count,
    ia.movie_infos
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_aggregated ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    info_aggregated ia ON mh.movie_id = ia.movie_id
WHERE 
    mh.depth = 0 OR mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, 
    ca.cast_count DESC
LIMIT 100;
