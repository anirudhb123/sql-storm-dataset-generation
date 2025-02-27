SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS comp_cast_type,
    c2.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
JOIN 
    movie_info m ON cc.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON cc.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND c.kind = 'cast' 
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, a.name;
