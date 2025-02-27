SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    role_type r ON cc.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, a.name;
