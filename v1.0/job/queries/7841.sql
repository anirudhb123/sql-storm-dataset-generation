
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    STRING_AGG(DISTINCT co.name, ',') AS companies,
    COUNT(DISTINCT r.id) AS role_count
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
    company_name co ON mc.company_id = co.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND t.title IS NOT NULL 
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 1 
ORDER BY 
    t.production_year DESC, actor_name;
