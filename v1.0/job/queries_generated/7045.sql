SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    y.info AS movie_info,
    t.production_year AS production_year,
    k.keyword AS movie_keyword
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    info_type it ON cc.subject_id = it.id
JOIN 
    movie_info y ON t.id = y.movie_id AND y.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
