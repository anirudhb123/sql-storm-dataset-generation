SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_name,
    COUNT(mk.keyword) AS keyword_count,
    COUNT(DISTINCT co.name) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(mk.keyword) > 0
ORDER BY 
    keyword_count DESC, a.name ASC, t.production_year DESC;
