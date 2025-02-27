SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id,
    c.nr_order,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    c.nr_order IS NOT NULL 
    AND t.production_year > 2000 
    AND a.name IS NOT NULL 
GROUP BY 
    a.name, t.title, c.role_id, c.nr_order
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    movie_title, actor_name;
