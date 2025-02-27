SELECT 
    t.title, 
    p.name AS actor_name, 
    c.kind AS role_type, 
    ak.year AS production_year, 
    ak.note AS movie_note
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ak.name IS NOT NULL 
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    actor_name;
