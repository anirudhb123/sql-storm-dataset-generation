SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS actor_role,
    co.name AS company_name,
    // Aggregating production year to get the count of movies per year
    COUNT(t.production_year) AS movie_count
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.role_id, co.name
ORDER BY 
    movie_count DESC, a.name ASC;
