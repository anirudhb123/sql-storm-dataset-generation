SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ci.note AS role_note,
    ti.info AS additional_info
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
