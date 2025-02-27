SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_identifier,
    COUNT(DISTINCT m.id) AS num_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.id, t.id, c.role_id
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    num_movies DESC, actor_name ASC;
