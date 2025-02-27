
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1,
        mh.path || ml.linked_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel') 
        AND NOT (ml.linked_movie_id = ANY(mh.path))
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT ch.id) AS character_count,
    MAX(m.production_year) AS latest_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE 
        WHEN mp.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS company_count, 
    RANK() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT ch.id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    char_name ch ON ch.imdb_index = m.imdb_index
LEFT JOIN 
    movie_companies mp ON mp.movie_id = m.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = m.id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = m.id
WHERE 
    mh.level <= 3
GROUP BY 
    a.id, m.id, a.name, m.title
HAVING 
    COUNT(DISTINCT ch.id) > 1 
ORDER BY 
    rank;
