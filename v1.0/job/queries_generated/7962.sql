SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.company_name AS production_company,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(ci.id) AS character_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND m.country_code = 'USA'
GROUP BY 
    a.name, t.title, m.company_name
HAVING 
    COUNT(DISTINCT k.id) > 5
ORDER BY 
    COUNT(ci.id) DESC, t.production_year DESC;
