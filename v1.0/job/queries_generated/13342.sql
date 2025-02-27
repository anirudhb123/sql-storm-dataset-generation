SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    rc.role AS role,
    c.name AS company_name,
    kt.keyword AS keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    role_type rc ON ci.role_id = rc.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
