WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    AVG(mi.info) AS average_rating,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info='rating')
WHERE
    ak.name IS NOT NULL AND ak.name <> ''
    AND (at.production_year BETWEEN 2000 AND 2023)
GROUP BY 
    ak.name, at.title, at.production_year
HAVING
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    rank, at.production_year DESC;
