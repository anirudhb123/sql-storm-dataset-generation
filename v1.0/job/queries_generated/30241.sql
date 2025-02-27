WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.title LIKE '%adventure%'
    
    UNION ALL

    SELECT 
        lm.linked_movie_id AS movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title mt ON lm.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON lm.movie_id = mh.movie_id
)

SELECT 
    aka.name AS actor_name,
    kh.keyword AS movie_keyword,
    rh.role AS character_role,
    mh.title AS movie_title,
    mh.depth AS movie_depth,
    COUNT(DISTINCT c.movie_id) OVER (PARTITION BY aka.person_id) AS total_movies,
    AVG(m.production_year) OVER () AS avg_production_year
FROM 
    aka_name aka
JOIN 
    cast_info c ON aka.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN 
    role_type rh ON c.role_id = rh.id
WHERE 
    aka.name IS NOT NULL
    AND (mh.depth < 3 OR mh.title IS NOT NULL)
ORDER BY 
    total_movies DESC, 
    actor_name ASC;

