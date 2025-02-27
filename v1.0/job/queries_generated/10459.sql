SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    cn.name AS company_name, 
    ct.kind AS company_type
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
    company_type AS ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
