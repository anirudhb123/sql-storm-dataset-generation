SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    ct.kind AS company_type,
    COUNT(*) AS total_movies,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) END) AS avg_movie_length
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND ct.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.role_id, ct.kind
HAVING 
    COUNT(*) > 10
ORDER BY 
    total_movies DESC, avg_movie_length DESC
LIMIT 20;
