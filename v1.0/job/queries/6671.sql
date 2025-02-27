SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    ci.note AS cast_note,
    ti.info AS movie_additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name co ON cc.subject_id = co.imdb_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
    AND k.keyword IN ('Action', 'Drama')
ORDER BY 
    a.name, t.production_year DESC;
