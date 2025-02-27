SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    tc.info AS company_info,
    k.keyword AS movie_keyword,
    cc.info AS cast_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.role = 'actor'
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
