SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    k.keyword AS movie_keyword,
    ci.note AS cast_note,
    m.year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name LIKE 'Robert%'
    AND t.production_year > 2000
    AND ci.nr_order < 5
ORDER BY 
    t.production_year DESC, a.name;
