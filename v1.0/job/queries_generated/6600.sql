SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    r.role AS actor_role,
    p.info AS actor_info,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_additional_info,
    COUNT(*) OVER (PARTITION BY t.id) AS total_cast
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000 
    AND p.info_type_id IN (1, 2) -- Example info types
    AND co.country_code = 'USA'
ORDER BY 
    t.title, c.name;
