SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    a.imdb_index AS aka_imdb_index,
    t.id AS title_id,
    t.title AS title_name,
    t.production_year,
    c.id AS cast_info_id,
    n.name AS person_name,
    n.gender,
    r.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name n ON a.person_id = n.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
