SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS cast_role,
    ci.name AS company_name,
    mk.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
