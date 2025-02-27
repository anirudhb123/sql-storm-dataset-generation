SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS character_note,
    ct.kind AS cast_type,
    m.production_year AS year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    year DESC, movie_title;
