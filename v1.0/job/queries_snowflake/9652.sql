SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    company_name cn ON cn.id = (
        SELECT mc.company_id 
        FROM movie_companies mc 
        WHERE mc.movie_id = t.id 
        LIMIT 1
    )
WHERE 
    a.name IS NOT NULL
    AND c.nr_order < 3
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, c.role_id
HAVING 
    COUNT(mk.keyword_id) > 0
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
