SELECT 
    t.title, 
    a.name AS actor_name, 
    c.note AS role_note, 
    m.company_id AS production_company_id, 
    c.nr_order AS cast_order
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
