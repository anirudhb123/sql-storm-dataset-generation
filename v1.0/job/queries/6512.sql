
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS cast_count, 
    COUNT(DISTINCT m.id) AS companies_count,
    MAX(t.production_year) AS latest_production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'birthdate')
GROUP BY 
    a.name, t.title, p.info
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    latest_production_year DESC
LIMIT 100;
