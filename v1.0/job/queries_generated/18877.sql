SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    m.company_id AS company_id,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies m ON t.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
