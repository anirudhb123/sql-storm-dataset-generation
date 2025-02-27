SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    grp.count AS num_actors,
    c.type AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    (SELECT 
         ci.movie_id, 
         COUNT(ci.person_id) AS count 
     FROM 
         cast_info ci 
     GROUP BY 
         ci.movie_id) grp ON t.id = grp.movie_id
WHERE 
    t.production_year > 2000 
    AND c.kind = 'Production' 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    num_actors DESC 
LIMIT 100;
