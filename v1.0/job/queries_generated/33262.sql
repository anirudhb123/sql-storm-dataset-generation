WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3 
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(ci.role_id, 'N/A') AS role_id,
    COUNT(DISTINCT ci.id) OVER (PARTITION BY h.movie_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS budget,
    MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS box_office
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info ci ON h.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id
LEFT JOIN 
    title t ON h.movie_id = t.id
LEFT JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    h.production_year > 2010
    AND (ci.note IS NULL OR ci.note <> 'extras')
GROUP BY 
    h.movie_id, h.title, h.production_year, ci.role_id
HAVING 
    CAST(COALESCE(MAX(mi.info), '0') AS INTEGER) >= 1000000
ORDER BY 
    h.production_year DESC, 
    h.title ASC;
