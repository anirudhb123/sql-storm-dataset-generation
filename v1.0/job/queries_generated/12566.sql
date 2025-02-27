SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    cct.kind AS company_type,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cct ON mc.company_type_id = cct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
