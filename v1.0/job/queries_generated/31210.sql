WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit levels of hierarchy
)
SELECT 
    a.name AS actor_name,
    m.movie_id,
    m.title,
    m.production_year,
    COUNT(DISTINCT gc.person_id) AS total_cast,
    STRING_AGG(DISTINCT g.keyword, ', ') AS movie_keywords,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY COUNT(DISTINCT gc.id) DESC) AS rank,
    CASE
        WHEN m.production_year < 2010 THEN 'Before 2010'
        WHEN m.production_year >= 2010 AND m.production_year < 2020 THEN '2010s'
        ELSE '2020s'
    END AS decade
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info gc ON m.movie_id = gc.movie_id
JOIN 
    aka_name a ON gc.person_id = a.person_id
LEFT JOIN 
    movie_keyword g ON m.movie_id = g.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT gc.person_id) > 1
ORDER BY 
    decade, total_cast DESC, m.title;
