SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.kind AS role_type,
    ak.title AS aka_title,
    ci.note AS cast_note
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    name n ON ak.person_id = n.imdb_id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, n.name;
