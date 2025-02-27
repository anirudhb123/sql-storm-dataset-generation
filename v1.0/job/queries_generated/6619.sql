SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
ORDER BY 
    t.production_year DESC, a.name;
