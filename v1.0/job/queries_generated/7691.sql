SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    r.role AS actor_role
FROM 
    aka_name a
INNER JOIN 
    cast_info ci ON a.person_id = ci.person_id
INNER JOIN 
    title t ON ci.movie_id = t.id
INNER JOIN 
    movie_companies mc ON t.id = mc.movie_id
INNER JOIN 
    company_name cn ON mc.company_id = cn.id
INNER JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name;
