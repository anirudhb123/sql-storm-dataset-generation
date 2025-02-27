SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS casting_type, 
    mc.note AS company_note, 
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND cn.country_code = 'USA' 
GROUP BY 
    a.id, t.id, c.kind, mc.note 
ORDER BY 
    t.production_year DESC;
