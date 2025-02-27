SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role_id,
    p.info AS actor_info,
    mc.company_type_id AS company_type_id,
    k.keyword AS movie_keyword,
    it.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name LIKE '%Smith%'
ORDER BY 
    t.title, a.name;
