SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ci.note AS role_note,
    cc.kind AS cast_type,
    c.name AS company_name,
    mi.info AS movie_info,
    mk.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    comp_cast_type cc ON ci.person_role_id = cc.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
    AND mk.keyword IN ('Action', 'Adventure')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
