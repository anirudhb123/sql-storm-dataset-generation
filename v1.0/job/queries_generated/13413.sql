SELECT 
    t.title as movie_title,
    a.name as actor_name,
    ct.kind as company_type,
    i.info as movie_info,
    k.keyword as movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = at.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
