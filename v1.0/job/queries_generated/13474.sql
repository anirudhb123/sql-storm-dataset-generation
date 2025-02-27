SELECT 
    a.name AS aka_name,
    t.title AS title,
    p.name AS person_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS person_role,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    company_name cn ON cn.id = (
        SELECT mc.company_id
        FROM movie_companies mc
        WHERE mc.movie_id = t.id
        LIMIT 1
    )
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON r.id = ci.person_role_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type ti ON ti.id = mi.info_type_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
