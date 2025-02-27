SELECT 
    t.title,
    c.name AS actor_name,
    cc.kind AS cast_type,
    mc.name AS company_name,
    i.info AS movie_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS an ON ci.person_id = an.person_id
JOIN 
    comp_cast_type AS cc ON ci.person_role_id = cc.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    movie_info AS i ON t.id = i.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
