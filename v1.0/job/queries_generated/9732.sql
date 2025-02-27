SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    COUNT(DISTINCT w.id) AS total_keywords,
    AVG(m.info_type_id) AS average_info_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword w ON t.id = w.movie_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, ct.kind
HAVING 
    COUNT(DISTINCT w.id) > 10
ORDER BY 
    total_keywords DESC, t.production_year ASC;
