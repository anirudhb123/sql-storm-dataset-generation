WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1,
        at.production_year
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(CASE 
            WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info)
            ELSE NULL 
        END) AS avg_info_length,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
    AND mh.level <= 5
    AND m.production_year IS NOT NULL
GROUP BY 
    ak.name, m.title, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    mh.level DESC, 
    avg_info_length DESC;

