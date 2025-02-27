SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    cc.note AS character_note,
    mk.keyword AS movie_keyword,
    ci.note AS company_note,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year >= 2000 
    AND ci.nr_order < 5 
ORDER BY 
    t.production_year DESC, a.name;
