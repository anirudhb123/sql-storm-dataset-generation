SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(k.keyword) AS keywords,
    COUNT(DISTINCT c.person_role_id) AS role_count,
    GROUP_CONCAT(DISTINCT co.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.id, t.id
HAVING 
    COUNT(DISTINCT k.id) > 0
ORDER BY 
    t.production_year DESC, actor_name ASC
LIMIT 100;
