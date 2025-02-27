WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies released after the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT ma.person_id) AS total_actors,
    AVG(CASE 
            WHEN pi.info_type_id = 2 THEN LENGTH(pi.info)
            ELSE NULL
        END) AS avg_person_age,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE 
            WHEN c.note IS NULL THEN 1 
            ELSE 0 
        END) AS null_notes_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id  -- Joining recursive CTE for movies
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT c.movie_id) > 1   -- Ensure the actor appears in more than one movie
ORDER BY 
    COUNT(DISTINCT c.movie_id) DESC, ak.name
LIMIT 10;
