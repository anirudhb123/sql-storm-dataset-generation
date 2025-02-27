SELECT 
    t.title,
    a.name AS actor_name,
    k.keyword AS movie_keyword,
    c.kind AS company_kind,
    p.info AS person_info,
    r.role AS role_type
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
