SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000 AND 
    co.country_code IN ('USA', 'UK') 
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 50;
