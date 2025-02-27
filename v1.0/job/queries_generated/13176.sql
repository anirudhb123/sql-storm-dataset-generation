SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    m.info AS company_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
WHERE 
    m.country_code = 'USA' 
    AND t.production_year >= 2000
ORDER BY 
    a.name, t.production_year;
