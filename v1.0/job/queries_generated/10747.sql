SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ct.kind AS cast_type,
    cn.name AS company_name,
    mi.info AS movie_info,
    ky.keyword AS movie_keyword,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ky ON mk.keyword_id = ky.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
ORDER BY 
    t.production_year DESC, 
    a.name;
