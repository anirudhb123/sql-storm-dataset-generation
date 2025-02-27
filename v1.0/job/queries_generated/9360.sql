SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.id) AS total_cast_members,
    GROUP_CONCAT(DISTINCT co.name) AS production_companies,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
INNER JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    a.id, t.id
ORDER BY 
    t.production_year DESC, a.name;
