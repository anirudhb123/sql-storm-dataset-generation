
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    company.name AS production_company,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT c.id) AS total_cast_members
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name company ON mc.company_id = company.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023 
    AND company.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, company.name
HAVING 
    COUNT(DISTINCT c.id) > 2
ORDER BY 
    t.production_year DESC, a.name;
