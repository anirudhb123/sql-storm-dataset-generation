WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2010
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2010
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT content.person_id) AS total_cast,
    STRING_AGG(DISTINCT co.name, ', ') AS crew_names,
    MAX(mh.depth) AS max_depth,
    AVG(mw.year) AS avg_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info content ON content.movie_id = mh.movie_id
LEFT JOIN 
    aka_name co ON co.person_id = content.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        EXTRACT(YEAR FROM CURRENT_DATE) - production_year AS year
    FROM 
        aka_title 
    WHERE 
        production_year IS NOT NULL
) mw ON mw.movie_id = mh.movie_id
WHERE 
    mh.title IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT content.person_id) > 3 AND 
    AVG(mw.year) < 20
ORDER BY 
    max_depth DESC, 
    total_cast DESC;

This query constructs a recursive Common Table Expression (CTE) to build a hierarchy of movies linked to titles produced from 2010 onwards. It aggregates data about the cast for each movie, including total cast members and crew names, while also calculating the maximum depth of links and average number of years since production. Finally, it filters and orders the results based on specified conditions.
