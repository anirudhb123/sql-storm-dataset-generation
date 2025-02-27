SELECT 
    ak.name AS aka_name, 
    ti.title AS movie_title, 
    ci.note AS cast_note, 
    co.name AS company_name, 
    rt.role AS role_name, 
    COUNT(DISTINCT mk.keyword) AS number_of_keywords 
FROM 
    aka_name ak 
JOIN 
    cast_info ci ON ak.person_id = ci.person_id 
JOIN 
    title ti ON ci.movie_id = ti.id 
JOIN 
    movie_companies mc ON ti.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    role_type rt ON ci.role_id = rt.id 
LEFT JOIN 
    movie_keyword mk ON ti.id = mk.movie_id 
WHERE 
    ti.production_year BETWEEN 2000 AND 2023 
AND 
    rt.role LIKE '%actor%' 
GROUP BY 
    ak.name, ti.title, ci.note, co.name, rt.role 
ORDER BY 
    number_of_keywords DESC, ti.title ASC;
