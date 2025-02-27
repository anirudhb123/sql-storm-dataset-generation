WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.imdb_index,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only movies
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.imdb_index,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only movies
)
SELECT 
    ah.name AS actor_name,
    m.movie_title,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ah ON ci.person_id = ah.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year IS NOT NULL 
AND 
    ah.name IS NOT NULL
GROUP BY 
    ah.name, m.movie_title
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 
ORDER BY 
    avg_production_year DESC,
    actor_name ASC;

This query constructs a recursive Common Table Expression (CTE) to build a hierarchy of movies and includes various joins, aggregates, string functions, and filtering conditions to retrieve performance metrics for actors associated with a defined number of companies, sorted by average production year and actor name.
