SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS role_type,
    k.keyword AS movie_keyword,
    ci.note AS cast_note
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, p.name;
