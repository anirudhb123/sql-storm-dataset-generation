SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.kind AS cast_role,
    m.production_year,
    km.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword km ON mk.keyword_id = km.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, t.title;
