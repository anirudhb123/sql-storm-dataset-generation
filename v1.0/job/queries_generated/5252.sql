SELECT 
    t.title AS movie_title,
    co.name AS company_name,
    a.name AS actor_name,
    k.keyword AS movie_keyword,
    p.info AS actor_info,
    ct.kind AS company_type,
    rc.role AS role_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type rc ON ci.role_id = rc.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name LIKE '%Smith%' 
    AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
ORDER BY 
    t.title, a.name;
