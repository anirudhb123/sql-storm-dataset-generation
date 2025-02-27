SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    rt.role AS role,
    c.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
