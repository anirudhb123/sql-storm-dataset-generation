WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    AVG(CASE WHEN ci.nm_order IS NOT NULL THEN ci.nm_order ELSE NULL END) AS Avg_Order,
    STRING_AGG(DISTINCT ak.name, ', ') AS Aka_Names,
    ARRAY_AGG(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL) AS Keywords,
    m.level AS Hierarchy_Level
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.level <= 3
GROUP BY 
    m.movie_id, m.title, m.production_year, m.level
ORDER BY 
    Avg_Order DESC NULLS LAST;
