SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ci.note AS cast_note,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
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
    a.name LIKE 'J%' 
    AND t.production_year > 2000
    AND ci.nr_order < 5
ORDER BY 
    a.name, t.production_year DESC;
