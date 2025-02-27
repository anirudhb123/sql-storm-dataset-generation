
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = at.id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, at.title, at.production_year, ak.id
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    at.production_year DESC, ak.name;
