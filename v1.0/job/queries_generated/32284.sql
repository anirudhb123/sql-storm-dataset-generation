WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id = 1  -- Assuming '1' is for movies

    UNION ALL

    SELECT 
        m.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link m ON mh.movie_id = m.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT m.keyword_id) AS keyword_count,
    AVG(l.language_id) AS avg_language,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY mt.production_year DESC) AS actor_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON mt.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword m ON m.movie_id = mt.movie_id
LEFT JOIN 
    movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Language')  -- Subquery for specific info type
LEFT JOIN 
    (SELECT DISTINCT 
        movie_id, 
        info AS language_id 
     FROM 
        movie_info 
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'Language')) l ON l.movie_id = mt.movie_id
LEFT JOIN 
    keyword k ON k.id = m.keyword_id
WHERE 
    mt.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.person_id, a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT m.keyword_id) > 0
ORDER BY 
    COUNT(*) DESC, actor_name;

-- This query explores all movies created between 2000 and 2020, 
-- lists actors, their movie titles, the total number of unique keywords associated with those movies, 
-- average language information, and ranks actors by their latest movies in descending order.
