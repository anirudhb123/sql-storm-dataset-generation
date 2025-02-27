
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS role_name,
    t.production_year AS year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
    AND cn.country_code = 'USA'
    AND k.keyword LIKE '%Drama%'
ORDER BY 
    t.production_year DESC, 
    a.name, 
    t.title;
