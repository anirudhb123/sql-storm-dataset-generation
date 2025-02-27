SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_role,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'BoxOffice')
ORDER BY 
    m.production_year DESC, 
    a.name;
