SELECT 
    at.title,
    ak.name AS actor_name,
    ct.kind AS role_type,
    t.production_year
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    title t ON at.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
