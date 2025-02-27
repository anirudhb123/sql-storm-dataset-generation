WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT c.id) OVER (PARTITION BY c.person_id) AS num_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN m.info END) AS rating,
    COUNT(DISTINCT ml.linked_movie_id) AS num_linked_movies,
    mh.level AS hierarchy_level
FROM 
    cast_info AS c
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    aka_title AS at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info AS m ON at.id = m.movie_id
LEFT JOIN 
    movie_link AS ml ON at.id = ml.movie_id
LEFT JOIN 
    MovieHierarchy AS mh ON at.id = mh.movie_id
WHERE 
    c.note IS NULL
GROUP BY 
    a.name, at.title, at.production_year, mh.level
HAVING 
    COUNT(DISTINCT m.info_type_id) > 1
ORDER BY 
    num_movies DESC, movie_title ASC;
