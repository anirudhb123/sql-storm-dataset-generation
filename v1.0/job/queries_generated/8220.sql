SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    m.name AS production_company, 
    k.keyword AS movie_keyword, 
    COUNT(DISTINCT c.id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND m.country_code = 'USA'
GROUP BY 
    a.name, t.title, m.name, k.keyword
HAVING 
    COUNT(DISTINCT c.id) > 2
ORDER BY 
    COUNT(DISTINCT c.id) DESC, t.title ASC;
