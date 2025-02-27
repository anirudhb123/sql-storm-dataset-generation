WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5 -- Limit depth of recursion
)

SELECT 
    COALESCE(a.name, 'Unknown') AS actor_name,
    t.title AS movie_title,
    t.production_year,
    CASE 
        WHEN c.role_id IS NOT NULL THEN ct.kind
        ELSE 'No Role Assigned'
    END AS role,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 -- Filter recent movies
    AND (k.keyword IS NULL OR k.keyword LIKE '%action%') -- Keywords filter
GROUP BY 
    actor_name, t.title, t.production_year, role
ORDER BY 
    linked_movies_count DESC, actor_name;
