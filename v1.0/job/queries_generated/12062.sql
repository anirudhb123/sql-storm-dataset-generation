SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id AS role,
    i.info AS additional_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
