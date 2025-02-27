SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year >= 2000 
    AND c.nr_order < 5
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    a.name, t.production_year DESC;
