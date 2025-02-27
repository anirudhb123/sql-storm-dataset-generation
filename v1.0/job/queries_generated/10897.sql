SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.id AS cast_id,
    c.note AS cast_note,
    p.id AS person_id,
    p.name AS person_name,
    r.role AS role_type,
    m.year AS production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    (SELECT DISTINCT production_year FROM aka_title) AS m ON t.production_year = m.production_year
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.id, t.id;
