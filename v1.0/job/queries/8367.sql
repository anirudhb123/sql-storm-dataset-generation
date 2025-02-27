SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    ct.kind AS company_type,
    i.info AS info_description
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year > 2000
    AND ct.kind LIKE '%Production%'
ORDER BY 
    t.production_year DESC, a.name ASC;
