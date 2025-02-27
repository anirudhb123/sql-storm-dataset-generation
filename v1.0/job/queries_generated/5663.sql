SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    p.info AS person_info,
    k.keyword AS keyword,
    ct.kind AS company_type,
    mi.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
