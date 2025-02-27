SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.name AS company_name,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name m ON m.id = mc.company_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
