WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    at.title AS "Title",
    at.production_year AS "Year",
    COUNT(DISTINCT ci.person_id) AS "Actor Count",
    SUM(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS "Info Count",
    STRING_AGG(DISTINCT cn.name, ', ') AS "Company Names",
    DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS "Rank by Actor Count",
    AVG(CASE WHEN mt.kind_id = kt.id THEN 1 ELSE NULL END) AS "Average Keywords"
FROM 
    aka_title at
LEFT JOIN 
    cast_info ci ON at.id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id 
WHERE 
    at.kind_id <> (SELECT id FROM kind_type WHERE kind = 'short' LIMIT 1) 
    AND at.production_year BETWEEN 2000 AND 2022
GROUP BY 
    at.id, at.title, at.production_year
ORDER BY 
    "Rank by Actor Count", at.production_year DESC;
