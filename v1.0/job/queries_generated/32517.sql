WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL  

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS companies_involved,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN CAST(mi.info AS FLOAT) ELSE NULL END) AS average_box_office,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND at.production_year >= 2000 
    AND (ak.name ILIKE '%Christopher%' OR ak.name ILIKE '%Leonardo%')
GROUP BY 
    ak.name, at.title
ORDER BY 
    companies_involved DESC,
    average_box_office DESC
LIMIT 20;
