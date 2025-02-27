SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    ci.note AS cast_note
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.nr_order = 1
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
WHERE 
    t.production_year > 2000 
    AND k.keyword LIKE '%action%'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, a.name;
