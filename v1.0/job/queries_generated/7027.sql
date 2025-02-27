SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS comp_cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(m.id) AS num_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.person_id, t.id, c.kind
HAVING 
    COUNT(m.id) > 1
ORDER BY 
    num_movies DESC;
