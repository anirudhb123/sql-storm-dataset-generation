SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS role_type,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, a.name;
