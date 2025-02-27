SELECT 
    t.title, 
    ak.name AS actor_name, 
    ci.note AS character_name, 
    m.name AS company_name 
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
