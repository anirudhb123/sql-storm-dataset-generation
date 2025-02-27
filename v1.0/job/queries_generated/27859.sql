SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    MAX(mi.info) AS additional_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    name p ON c.person_id = p.imdb_id
WHERE 
    ak.name LIKE '%Smith%'
    AND ct.kind = 'Production'
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    ak.name, t.title, p.name, ct.kind
ORDER BY 
    num_companies DESC, t.title;
