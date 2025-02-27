WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1,
        CAST(h.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy h ON h.movie_id = ml.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.id) AS appearances,
    AVG(CASE WHEN i.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
             THEN CAST(i.info AS FLOAT) ELSE NULL END) AS avg_rating,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info i ON m.id = i.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1 
ORDER BY 
    avg_rating DESC NULLS LAST, 
    appearances DESC,
    actor_name ASC;