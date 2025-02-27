SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_name,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    char_name c ON a.id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
