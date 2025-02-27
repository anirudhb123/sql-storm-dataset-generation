WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(aka.name, ''), 'Unknown') AS movie_name,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_name aka ON aka.person_id = mt.id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(NULLIF(aka.name, ''), 'Unknown') AS movie_name,
        h.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
    INNER JOIN 
        title mv ON ml.linked_movie_id = mv.id
    LEFT JOIN 
        aka_name aka ON aka.person_id = mv.id
)
SELECT 
    mhd.movie_id,
    mhd.title,
    mhd.production_year,
    mhd.movie_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT p.info, ', ') AS person_info,
    SUM(CASE WHEN mw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order
FROM 
    MovieHierarchy mhd
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mhd.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    person_info p ON p.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = mhd.movie_id
WHERE 
    mhd.level <= 3
GROUP BY 
    mhd.movie_id, mhd.title, mhd.production_year, mhd.movie_name
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    keyword_count DESC,
    average_order ASC
LIMIT 50;
