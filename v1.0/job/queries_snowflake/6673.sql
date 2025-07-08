SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    co.name AS company_name,
    ct.kind AS company_type,
    COUNT(mk.id) AS keyword_count
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
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND t.production_year >= 2000
    AND co.country_code = 'USA'
GROUP BY 
    ak.name, t.title, c.person_role_id, co.name, ct.kind
ORDER BY 
    keyword_count DESC, t.title ASC
LIMIT 100;
