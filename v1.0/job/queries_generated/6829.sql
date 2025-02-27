SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.production_year, 
    COUNT(*) AS number_of_movies 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
GROUP BY 
    a.name, t.title, c.kind, m.production_year 
HAVING 
    COUNT(*) > 1 
ORDER BY 
    production_year DESC, number_of_movies DESC;
