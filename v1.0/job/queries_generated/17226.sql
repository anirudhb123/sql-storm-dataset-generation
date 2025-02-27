SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS cast_note,
    ct.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info ti ON m.id = ti.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC;
