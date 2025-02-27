SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    ci.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.movie_id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS ci ON mc.company_type_id = ci.id
JOIN 
    movie_info AS mi ON t.movie_id = mi.movie_id
WHERE 
    a.name LIKE 'A%'
ORDER BY 
    t.production_year DESC;
