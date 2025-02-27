SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.role_id AS cast_role,
    cc.kind AS comp_cast_kind,
    ci.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ci.country_code = 'USA'
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name ASC;
