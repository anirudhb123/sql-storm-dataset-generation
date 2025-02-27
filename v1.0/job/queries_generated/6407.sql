SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    co.name AS company_name,
    tk.keyword AS movie_keyword,
    pi.info AS person_info,
    ti.production_year AS year_produced
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
