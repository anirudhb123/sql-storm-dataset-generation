SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type,
    COUNT(mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year END) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, p.info, c.kind
ORDER BY 
    total_movies DESC,
    a.name ASC;
