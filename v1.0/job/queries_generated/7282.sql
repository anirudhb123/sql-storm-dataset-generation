SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_name,
    co.name AS company_name,
    ti.info AS movie_info,
    COUNT(mk.keyword) AS keyword_count
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
    AND cct.kind = 'acting'
GROUP BY 
    n.name, t.title, c.kind, co.name, ti.info
ORDER BY 
    keyword_count DESC, t.production_year ASC
LIMIT 100;
