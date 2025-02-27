WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- Starting point for movies after 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    h.title,
    h.production_year,
    k.keyword,
    COUNT(ci.person_id) AS cast_count,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS presence_score,
    STRING_AGG(DISTINCT n.name, ', ') AS actor_names
FROM 
    movie_hierarchy h
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    h.level <= 2 -- Looking into a maximum depth of 2 for hierarchy
GROUP BY 
    h.title, h.production_year, k.keyword
HAVING 
    COUNT(ci.person_id) > 5
ORDER BY 
    h.production_year DESC, h.title;

This SQL query creates a recursive Common Table Expression (CTE) to explore a hierarchy of movies linked to each other, starting from titles produced after 2000. It retrieves the movie titles, production years, associated keywords, the count of casting members for each movie, a presence score to indicate if casting notes are available (with NULL logic), and a concatenated list of actor names. The results are restricted to movies with more than five casting members and are ordered by the production year and title.
