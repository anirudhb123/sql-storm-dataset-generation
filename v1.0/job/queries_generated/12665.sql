SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS role,
    m.production_year,
    g.info AS genre
FROM 
    title t
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    movie_info m ON m.movie_id = t.id
JOIN 
    info_type g ON g.id = m.info_type_id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC;
