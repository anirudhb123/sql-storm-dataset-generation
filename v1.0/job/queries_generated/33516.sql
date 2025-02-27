WITH RECURSIVE MovieHierarchy AS (
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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY mh.production_year DESC) AS actor_movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
WHERE 
    mh.depth <= 2
    AND t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.id, a.name, t.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    actor_movie_rank, linked_movies_count DESC;
