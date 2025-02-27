WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level,
        CAST(mh.full_title || ' -> ' || at.title AS VARCHAR(255)) AS full_title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    MAX(m.production_year) AS latest_year,
    STRING_AGG(DISTINCT m.title, '; ') AS movie_titles,
    AVG(m.production_year) FILTER (WHERE m.production_year IS NOT NULL) AS avg_production_year,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
ORDER BY 
    movie_count DESC, latest_year DESC
LIMIT 10;
