SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    i.info AS movie_info
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS tc ON mc.company_type_id = tc.id
JOIN 
    movie_info AS i ON t.id = i.movie_id
WHERE 
    t.production_year = 2023
ORDER BY 
    a.name, t.title;
