WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.full_path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        movie_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    h.full_path,
    h.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE 
        WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
        ELSE 0 
    END) AS avg_order
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    h.production_year IS NOT NULL AND
    h.level <= 3
GROUP BY 
    h.full_path, h.production_year
ORDER BY 
    h.production_year DESC, total_cast DESC
LIMIT 50;
