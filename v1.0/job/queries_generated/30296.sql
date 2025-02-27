WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(ci.person_id) AS total_actors,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_note,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MIN(m.movie_id) AS min_movie_id,
    MAX(m.movie_id) AS max_movie_id
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    keyword k ON k.id IN (SELECT keyword_id FROM movie_keyword WHERE movie_id = mh.movie_id)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(ci.person_id) > 10 -- Only movies with more than 10 actors
ORDER BY 
    mh.production_year DESC, 
    total_actors DESC
LIMIT 50;


This query includes a recursive CTE to build a hierarchy of movies linked to each other, counts the total number of actors in each movie, calculates an average presence of notes for each actor, and aggregates actor names into a comma-separated string. It applies filters to ensure only movies with more than ten actors are considered, ordered by production year and actor count, limiting the result to 50 entries. The use of outer joins and subqueries enhance complexity and provide additional insights into movie details.
