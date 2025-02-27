SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
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
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.imdb_index IS NOT NULL
    AND co.country_code IN ('USA', 'UK', 'CAN')
ORDER BY 
    t.production_year DESC, actor_name;
