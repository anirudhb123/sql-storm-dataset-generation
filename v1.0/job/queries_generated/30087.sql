WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        mt.title,
        mt.production_year,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy m ON ml.movie_id = m.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(p.age) AS average_age,
    MAX(CASE WHEN c.role_id = (SELECT id FROM role_type WHERE role='Lead') THEN 1 ELSE 0 END) AS is_lead
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_hierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword k ON m.movie_id = k.movie_id
LEFT JOIN 
    (SELECT 
         person_id,
         EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birth_date) AS age
     FROM 
         person_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'birth_date')
    ) p ON p.person_id = a.person_id
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    AVG(p.age) > 30 AND COUNT(DISTINCT k.keyword) > 3
ORDER BY 
    m.production_year DESC, actor_name ASC;

This query includes:
- A recursive CTE to create a movie hierarchy that collects movies and their linked movies.
- Joins across different tables (cast_info, aka_name, and movie_keyword) to aggregate relevant movie and actor information.
- Conditional aggregation to check if an actor has a lead role and to calculate the actor's average age.
- Grouping with a HAVING clause to filter for actors over a certain age and movies with a high number of keywords.
- Ordered results based on production year and actor name for improved readability.
