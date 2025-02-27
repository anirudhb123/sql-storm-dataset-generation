SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    title t ON t.id = ci.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON c.id = mc.company_type_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    a.name_pcode_cf IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    keyword_count DESC, t.production_year DESC;
