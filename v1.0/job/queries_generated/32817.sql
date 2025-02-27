WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        cm.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link cm
    JOIN 
        aka_title a ON cm.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = cm.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE WHEN m.production_year < 2010 THEN 1 ELSE 0 END) AS avg_classic_movie_appearance,
    MAX(b.level) AS max_depth
FROM 
    movie_keyword mk
JOIN 
    aka_title at ON mk.movie_id = at.id
LEFT JOIN 
    cast_info c ON at.id = c.movie_id
LEFT JOIN 
    MovieHierarchy b ON at.id = b.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 10
ORDER BY 
    actor_count DESC;

