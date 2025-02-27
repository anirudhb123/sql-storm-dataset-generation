SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT co.id) AS cast_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year > 2000 
    AND ak.name LIKE 'A%' 
GROUP BY 
    ak.name, t.title, c.person_role_id, p.info
ORDER BY 
    COUNT(DISTINCT mc.company_id) DESC, 
    ak.name, 
    t.title;
