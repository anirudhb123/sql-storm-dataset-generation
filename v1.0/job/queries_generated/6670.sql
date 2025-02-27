SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id AS role_id, 
    m.info AS movie_info, 
    k.keyword AS movie_keyword, 
    COUNT(m.id) AS number_of_movies 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year > 2000 
    AND c.nr_order < 5 
GROUP BY 
    a.name, t.title, c.role_id, m.info, k.keyword 
HAVING 
    COUNT(m.id) > 1 
ORDER BY 
    number_of_movies DESC, a.name ASC 
LIMIT 100;
