SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS role_type,
    cn.name AS company_name,
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
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN 
    movie_keyword mw ON t.id = mw.movie_id
LEFT JOIN 
    keyword k ON mw.keyword_id = k.id
WHERE 
    t.production_year >= 2000 AND 
    cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
