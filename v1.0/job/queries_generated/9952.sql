SELECT 
    t.title AS movie_title,
    c.name AS cast_member_name,
    rc.role AS cast_role,
    co.name AS company_name,
    mt.kind AS company_type,
    ti.info AS additional_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    char_name cn ON an.name = cn.name
JOIN 
    role_type rc ON ci.role_id = rc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    movie_title ASC;
