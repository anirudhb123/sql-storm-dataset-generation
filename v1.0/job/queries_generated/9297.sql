SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_name, 
    mc.note AS company_note, 
    ki.keyword AS movie_keyword, 
    pi.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    movie_companies AS mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id
JOIN 
    role_type AS r ON ci.role_id = r.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    actor_name ASC
LIMIT 50;
