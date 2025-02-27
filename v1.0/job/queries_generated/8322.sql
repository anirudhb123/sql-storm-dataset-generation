SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS company_type, 
    COUNT(mk.keyword) AS keyword_count, 
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, a.name ASC;
