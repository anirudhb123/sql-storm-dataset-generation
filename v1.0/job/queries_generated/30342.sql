WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mlt.linked_movie_id AS related_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mlt ON mt.id = mlt.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        mlt.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.related_movie_id = mt.id
    LEFT JOIN 
        movie_link mlt ON mt.id = mlt.movie_id
    WHERE 
        mh.level < 3 -- Limit the depth of recursion
)

SELECT 
    ak.id AS aka_id,
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(pi.info)::DECIMAL(10, 2) AS avg_person_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ak.name IS NOT NULL
    AND mh.level = 1 -- Flat level of movie hierarchy
    AND (pi.info_type_id IS NULL OR pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography'))
GROUP BY 
    ak.id, ak.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.id) > 3
ORDER BY 
    mh.production_year DESC, avg_person_info DESC;
