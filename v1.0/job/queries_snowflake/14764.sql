SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.gender AS actor_gender,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    r.role AS actor_role
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    name p ON ak.person_id = p.imdb_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name;
