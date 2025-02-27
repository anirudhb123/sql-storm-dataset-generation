SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.kind AS role_kind,
    p.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    person_info p ON n.id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, n.name;
