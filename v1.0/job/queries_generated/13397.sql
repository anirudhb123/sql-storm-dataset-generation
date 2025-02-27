SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    info.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type info ON mi.info_type_id = info.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, p.name;
