SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    c.kind AS company_kind, 
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    total_movies DESC, actor_name
LIMIT 50;
