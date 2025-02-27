SELECT 
    t.title,
    a.name AS actor_name,
    ci.note AS actor_note,
    c.name AS company_name,
    ci.nr_order AS actor_order,
    ti.info AS movie_info
FROM 
    title AS t
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    cast_info AS ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_info AS ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
