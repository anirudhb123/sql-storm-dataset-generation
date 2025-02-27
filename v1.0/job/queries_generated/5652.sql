SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    AND ci.nr_order < 5
ORDER BY 
    t.production_year DESC, actor_name;
