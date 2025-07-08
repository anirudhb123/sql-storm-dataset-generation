SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    co.name AS company_name,
    COUNT(DISTINCT mw.id) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS average_rating,
    p.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mw ON t.id = mw.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND co.country_code = 'USA'
GROUP BY 
    ak.name, t.title, c.role_id, co.name, p.info
ORDER BY 
    keyword_count DESC, average_rating DESC;
