WITH RECURSIVE movie_chain AS (
    SELECT 
        mc.movie_id,
        a.title,
        1 AS movie_level
    FROM 
        movie_companies mc
    JOIN 
        aka_title a ON mc.movie_id = a.movie_id
    WHERE 
        mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a2.title,
        mc.movie_level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_chain mc ON ml.movie_id = mc.movie_id
    JOIN 
        aka_title a2 ON ml.linked_movie_id = a2.movie_id
)
SELECT 
    a.name AS actor_name,
    a2.title AS movie_title,
    COUNT(DISTINCT m.id) AS total_movies,
    COUNT(DISTINCT mc.movie_id) AS chained_movies,
    SUM(service_count) AS services_count,
    MAX(production_year) AS last_release_year
FROM 
    movie_chain mc
JOIN 
    cast_info ci ON mc.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title a2 ON mc.movie_id = a2.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT company_id) AS service_count 
     FROM 
         movie_companies 
     WHERE 
         company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
     GROUP BY 
         movie_id) AS services ON services.movie_id = mc.movie_id
WHERE 
    ci.role_id IS NOT NULL 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, a2.title
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    total_movies DESC, last_release_year DESC
LIMIT 100;
