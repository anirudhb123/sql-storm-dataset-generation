WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Only top-level movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1  -- Increment level for each linked movie
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_actors,
    AVG(COALESCE(pi.year_of_birth, 1900)) AS average_actor_birth_year,  -- Using COALESCE for NULL handling
    STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords  -- Aggregate keywords into a comma-separated string
FROM 
    complete_cast cc
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    aka_title at ON mc.movie_id = at.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth year') 
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mh.production_year >= 2000  -- Filter for movies released after 2000
    AND ak.name IS NOT NULL  -- Exclude NULL actor names
GROUP BY 
    ak.name,
    at.title,
    mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5  -- Only include movies with more than 5 actors
ORDER BY 
    mh.production_year DESC, 
    total_actors DESC;
