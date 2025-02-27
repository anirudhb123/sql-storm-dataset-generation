SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS company_names, 
    GROUP_CONCAT(DISTINCT kw.keyword SEPARATOR ', ') AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
GROUP BY 
    actor_name, movie_title, t.production_year 
ORDER BY 
    t.production_year DESC, actor_name;
