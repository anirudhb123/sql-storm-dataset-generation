SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    tk.keyword AS keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
