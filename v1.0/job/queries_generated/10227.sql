SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    t.production_year,
    COUNT(*) AS appearance_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.role_id, t.production_year
ORDER BY 
    appearance_count DESC
LIMIT 10;
