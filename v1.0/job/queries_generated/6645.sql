SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.company_name AS production_company,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT c.id) AS total_companies,
    COUNT(DISTINCT mi.id) AS total_movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY 
    ak.name, t.title, p.name, c.company_name, k.keyword
ORDER BY 
    total_companies DESC, total_movie_info DESC
LIMIT 100;
