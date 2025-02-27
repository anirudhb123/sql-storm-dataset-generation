SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword LIKE '%action%'
    AND c.kind IN ('actor', 'actress')
ORDER BY 
    t.production_year DESC, 
    p.name ASC
LIMIT 50;
