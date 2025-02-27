SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    c2.name AS company_name, 
    p.info AS person_info,
    COUNT( DISTINCT k.keyword ) AS total_keywords,
    COUNT( DISTINCT ci.id ) AS cast_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND c2.country_code = 'USA'
GROUP BY 
    ak.name, t.title, c2.name, p.info
ORDER BY 
    cast_count DESC, total_keywords DESC;
