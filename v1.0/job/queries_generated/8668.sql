SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS cast_type, 
    p.info AS person_info,
    m.info AS movie_info,
    k.keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year > 2000 
AND 
    a.name IS NOT NULL 
AND 
    cn.country_code = 'USA'
ORDER BY 
    t.title, a.name;
