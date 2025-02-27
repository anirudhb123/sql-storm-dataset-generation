WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        m2.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(cit.kind, 'Unknown') AS company_type,
    MAX(mh.level) AS hierarchical_depth
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type cit ON mc.company_type_id = cit.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL 
    AND t.kind_id IS NOT NULL
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, m.production_year, cit.kind
ORDER BY 
    actor_count DESC, m.production_year DESC;

This query constructs a hierarchical view of movies linked through the `movie_link` table while also aggregating various attributes like actor counts and keywords associated with each movie. The result includes data on actors, their movie titles, production years, and the type of company associated with each movie, along with the hierarchical depth of related movies. It utilizes a recursive common table expression (CTE), outer joins, window functions, and string aggregation to produce a comprehensive dataset suited for performance benchmarking.
