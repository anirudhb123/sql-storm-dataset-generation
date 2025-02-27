SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.company_name AS production_company,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    role_type r ON r.id = ci.role_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON c.id = mc.company_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND r.role IN ('actor', 'director')
    AND k.keyword LIKE '%drama%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
