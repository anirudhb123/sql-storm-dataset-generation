WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(mh.depth) OVER (PARTITION BY mh.production_year) AS avg_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE 
    mh.production_year IS NOT NULL
    AND (mh.depth > 1 OR mh.depth IS NULL)
GROUP BY 
    a.name, t.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    mh.production_year DESC, cast_count DESC;

