SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    cc.status_id AS cast_status,
    r.role AS role_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    company_name cn ON ci.movie_id IN (SELECT movie_id FROM movie_companies WHERE company_id = cn.id)
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, a.name;
