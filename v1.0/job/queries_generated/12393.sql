SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.id AS title_id, 
    t.title AS movie_title, 
    GROUP_CONCAT(DISTINCT c.person_role_id) AS roles,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type r ON ci.role_id = r.id
GROUP BY 
    a.id, a.name, t.id, t.title
ORDER BY 
    t.production_year DESC, a.name;
