SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT ci.company_id) AS company_count
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND cn.country_code = 'USA'
GROUP BY 
    t.id, a.id, c.role_id
ORDER BY 
    keyword_count DESC, company_count DESC;
