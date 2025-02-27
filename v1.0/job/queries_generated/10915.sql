SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS production_year,
    c.role_id AS role_id,
    co.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
