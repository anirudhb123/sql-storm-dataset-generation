SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rt.role AS role,
    tc.company_name AS production_company,
    tk.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name tc ON mc.company_id = tc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    rt.role IN ('Actor', 'Director')
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    tk.keyword ASC;
