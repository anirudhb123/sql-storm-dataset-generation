WITH RECURSIVE film_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        fh.level + 1,
        fh.path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        film_hierarchy fh ON ml.movie_id = fh.movie_id
)
SELECT 
    fh.movie_title,
    COUNT(*) FILTER (WHERE ci.role_id IS NOT NULL) AS num_roles,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    MAX(CASE WHEN ti.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') THEN ti.info END) AS duration,
    MAX(CASE WHEN ti.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN ti.info END) AS rating,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    film_hierarchy fh
LEFT JOIN 
    complete_cast cc ON fh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = fh.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_info ti ON fh.movie_id = ti.movie_id
LEFT JOIN 
    movie_keyword mk ON fh.movie_id = mk.movie_id
WHERE 
    fh.level <= 3
GROUP BY 
    fh.movie_title
ORDER BY 
    num_roles DESC, rating DESC NULLS LAST, keyword_count DESC;
