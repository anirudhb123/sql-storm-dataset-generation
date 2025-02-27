SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS character_type,
    kt.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC;
