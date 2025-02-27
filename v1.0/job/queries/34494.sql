
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title mt ON ml.movie_id = mt.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_cast_size
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mc.company_id IN (
        SELECT id 
        FROM company_name 
        WHERE country_code = 'USA'
    ) 
    AND (m.production_year IS NOT NULL AND m.production_year > 1990)
GROUP BY 
    a.name, m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    m.production_year DESC, total_cast DESC;
