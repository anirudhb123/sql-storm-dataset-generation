WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 is the kind_id for feature films
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.level,
    h.path,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    MAX(CASE WHEN ci.person_role_id IS NULL THEN 'Unknown Role' 
             ELSE r.role END) AS primary_role,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    CASE 
        WHEN h.production_year < 2000 THEN 'Before 2000'
        WHEN h.production_year BETWEEN 2000 AND 2010 THEN '2000s'
        ELSE '2010s and later'
    END AS era
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info ci ON h.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    h.movie_id, h.title, h.production_year, h.level, h.path
ORDER BY 
    h.production_year DESC, total_cast DESC;
