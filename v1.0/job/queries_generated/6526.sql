SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    ct.kind AS company_type,
    ci.note AS cast_note
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
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Producer'
ORDER BY 
    t.production_year DESC, a.name;
