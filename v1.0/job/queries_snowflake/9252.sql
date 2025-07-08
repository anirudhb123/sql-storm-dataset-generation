SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.name AS production_company, 
    ti.info AS movie_info, 
    k.keyword AS movie_keyword
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2022 
    AND m.country_code = 'USA' 
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
