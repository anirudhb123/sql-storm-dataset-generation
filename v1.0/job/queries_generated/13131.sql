SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role,
    m.production_year,
    kc.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
