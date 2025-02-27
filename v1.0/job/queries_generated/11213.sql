SELECT 
    t.title,
    t.production_year,
    a.name AS actor_name,
    c.kind AS cast_type,
    cn.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
