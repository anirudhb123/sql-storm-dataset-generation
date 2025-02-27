SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ci.note AS role_note,
    mc.note AS company_note,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.title IS NOT NULL
ORDER BY 
    a.name, t.title;
