SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS cast_kind, 
    COUNT(DISTINCT mc.company_id) AS production_companies, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND ct.kind = 'Production' 
GROUP BY 
    a.id, t.id, c.kind 
ORDER BY 
    t.production_year DESC, actor_name ASC
LIMIT 100;
