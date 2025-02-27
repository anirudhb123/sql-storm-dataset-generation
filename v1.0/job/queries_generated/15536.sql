SELECT 
    t.title,
    a.name AS actor_name,
    ci.note AS role_note,
    c.name AS company_name,
    kt.keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
