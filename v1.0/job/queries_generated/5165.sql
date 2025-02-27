SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mu.info AS movie_info
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
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info mu ON t.id = mu.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    k.keyword LIKE '%action%'
AND 
    co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
