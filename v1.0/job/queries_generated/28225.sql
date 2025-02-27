SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    COUNT(DISTINCT ci.id) AS cast_count,
    STRING_AGG(DISTINCT r.role, ', ') AS roles,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name ASC) AS companies,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.id, t.id
ORDER BY 
    cast_count DESC, movie_title
LIMIT 10;
