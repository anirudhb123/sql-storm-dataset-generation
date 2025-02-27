WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    UNION ALL
    SELECT 
        mc.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        title m ON mc.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
),
cast_enrichment AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
info_composite AS (
    SELECT 
        m.movie_id,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE 0 END), 0) AS total_info_length,
        COALESCE(MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END), 'No Info') AS last_Iinfo,
        MIN(CASE WHEN mi.info IS NULL THEN 1 ELSE 0 END) AS has_nulls
    FROM 
        movie_info mi
    JOIN 
        movie_hierarchy m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ce.total_cast,
    ce.cast_names,
    ic.total_info_length,
    ic.last_Iinfo,
    ic.has_nulls
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_enrichment ce ON mh.movie_id = ce.movie_id
LEFT JOIN 
    info_composite ic ON mh.movie_id = ic.movie_id
WHERE 
    mh.level = (SELECT MAX(level) FROM movie_hierarchy) 
    AND ic.total_info_length > 0
ORDER BY 
    mh.production_year DESC,
    mh.title;
