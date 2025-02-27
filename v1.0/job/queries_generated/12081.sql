-- Performance Benchmarking Query for Join Order
SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_info_id,
    c.note AS cast_note,
    cn.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS mt ON mc.company_type_id = mt.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
