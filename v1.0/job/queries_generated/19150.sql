SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info ti ON t.movie_id = ti.movie_id
WHERE 
    ti.info_type_id = 1
ORDER BY 
    a.name, t.title;
