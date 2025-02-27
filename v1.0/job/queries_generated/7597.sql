SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_biography,
    c.kind AS cast_type,
    m.name AS production_company,
    k.keyword AS movie_keyword
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
AND 
    m.country_code = 'USA'
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
