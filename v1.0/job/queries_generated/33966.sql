WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    string_agg(DISTINCT ag.name || ' (' || ag.kind || ')', ', ') AS agents,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(m.production_year) AS avg_production_year
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    company_name ag ON ag.imdb_id = ak.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id AND mc.company_id = ag.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
JOIN 
    aka_title m ON m.id = c.movie_id
LEFT JOIN 
    info_type it ON it.id = c.note
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
    AND (m.production_year > 2010 AND m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%'))
GROUP BY 
    a.id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC, avg_production_year ASC;
