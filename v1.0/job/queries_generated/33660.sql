WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        aka_title a ON mk.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COALESCE(SUM(mk.id), 0) AS total_keywords,
    COUNT(DISTINCT c.role_id) AS distinct_roles,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY mh.production_year DESC) AS role_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.level <= 2 AND
    a.name IS NOT NULL AND
    at.production_year > 2000
GROUP BY 
    a.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.role_id) > 1
ORDER BY 
    total_keywords DESC,
    a.name ASC;
