SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    tc.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    COUNT(DISTINCT k.keyword) AS total_keywords,
    MIN(m.production_year) AS first_movie_year,
    MAX(m.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type tc ON mc.company_type_id = tc.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON at.id = m.id
WHERE 
    a.name LIKE 'A%' 
    AND m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, at.title, tc.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    total_companies DESC, actor_name;
