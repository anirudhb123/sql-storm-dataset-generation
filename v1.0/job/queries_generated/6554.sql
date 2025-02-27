SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS character_note,
    ci.nr_order AS cast_order,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keywords,
    cn.name AS company_name,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 AND 
    ci.nr_order < 5
ORDER BY 
    a.name, t.production_year DESC, ci.nr_order;
