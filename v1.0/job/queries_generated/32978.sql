WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        m.production_year,
        m.imdb_index,
        CAST(m.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mk.linked_movie_id AS movie_id,
        mk.linked_movie_id AS movie_title,
        mh.level + 1,
        m.production_year,
        m.imdb_index,
        CAST(CONCAT(mh.full_title, ' -> ', mk.linked_movie_id) AS VARCHAR(255)) AS full_title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mk ON mh.movie_id = mk.movie_id
    JOIN 
        aka_title m ON mk.linked_movie_id = m.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    MAX(h.level) AS max_level,
    STRING_AGG(DISTINCT h.full_title, ' | ') AS movie_chain,
    COALESCE(CAST(ROUND(AVG(m.info::DECIMAL), 2) AS VARCHAR), 'No Info') AS average_movie_rating
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    MovieHierarchy h ON t.id = h.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    (SELECT DISTINCT movie_id, info FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    t.production_year DESC, max_level ASC;
