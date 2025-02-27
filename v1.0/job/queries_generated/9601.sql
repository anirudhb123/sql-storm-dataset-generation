SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    GROUP_CONCAT(DISTINCT kc.keyword ORDER BY kc.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(m.production_year) AS avg_production_year
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND cn.country_code = 'USA' 
GROUP BY 
    a.id, t.id, c.id
HAVING 
    total_movies > 5
ORDER BY 
    avg_production_year DESC;
