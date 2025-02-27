SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    ct.kind AS cast_type,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order;
