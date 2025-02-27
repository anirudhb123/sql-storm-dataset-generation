SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    mt.kind AS company_type,
    kw.keyword AS movie_keyword,
    info.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mw ON t.movie_id = mw.movie_id
JOIN 
    keyword kw ON mw.keyword_id = kw.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    info_type info ON mi.info_type_id = info.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
