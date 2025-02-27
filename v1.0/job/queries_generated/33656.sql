WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title AS t
    JOIN 
        movie_link AS ml ON t.id = ml.movie_id
    JOIN 
        title AS m ON ml.linked_movie_id = m.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        title AS t ON ml.linked_movie_id = t.id
)
SELECT 
    persons.name AS actor_name,
    movies.title AS movie_title,
    movies.production_year,
    COUNT(mh.movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
    AVG(CASE WHEN cast.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note,
    MAX(CASE WHEN c.kind = 'main' THEN 1 ELSE 0 END) AS is_main_cast
FROM 
    cast_info AS cast
JOIN 
    aka_name AS persons ON cast.person_id = persons.person_id
JOIN 
    title AS movies ON cast.movie_id = movies.id
LEFT JOIN 
    movie_keyword AS mk ON movies.id = mk.movie_id
LEFT JOIN 
    keyword AS keyword ON mk.keyword_id = keyword.id
LEFT JOIN 
    movie_hierarchy AS mh ON movies.id = mh.movie_id
LEFT JOIN 
    comp_cast_type AS c ON cast.person_role_id = c.id
WHERE 
    movies.production_year BETWEEN 2000 AND 2023
    AND persons.name IS NOT NULL
GROUP BY 
    persons.name,
    movies.title,
    movies.production_year
ORDER BY 
    movies.production_year DESC,
    linked_movies_count DESC,
    actors.name;
