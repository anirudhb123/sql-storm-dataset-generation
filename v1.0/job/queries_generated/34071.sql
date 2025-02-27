WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    COALESCE(SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count,
    MIN(t.production_year) AS first_movie_year,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON cc.movie_id = mk.movie_id
LEFT JOIN 
    aka_title t ON cc.movie_id = t.id
WHERE 
    a.name IS NOT NULL AND a.name <> ''
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT cc.movie_id) > 10
ORDER BY 
    total_movies DESC, 
    actor_name ASC;
