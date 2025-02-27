SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    ct.kind AS company_type,
    m.title AS movie_title_info,
    info.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    title m ON mc.movie_id = m.id
LEFT JOIN 
    movie_info info ON m.id = info.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    a.name, t.production_year;
