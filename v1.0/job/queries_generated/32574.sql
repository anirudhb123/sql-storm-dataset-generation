WITH RECURSIVE recursive_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        lm.id AS movie_id,
        lm.title,
        lm.production_year,
        rm.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lm ON ml.linked_movie_id = lm.id
    JOIN 
        recursive_movies rm ON ml.movie_id = rm.movie_id
    WHERE 
        lm.production_year IS NOT NULL 
)

SELECT 
    ak.name AS actor_name,
    rt.role AS role,
    COALESCE(kw.keyword, 'N/A') AS movie_keyword,
    rm.title AS linked_movie,
    rm.production_year AS linked_movie_year,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_percentage,
    RANK() OVER (PARTITION BY rt.role ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS role_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    recursive_movies rm ON ci.movie_id = rm.movie_id
GROUP BY 
    ak.name, rt.role, rm.title, rm.production_year, kw.keyword
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2
ORDER BY 
    role_rank, total_movies DESC;
