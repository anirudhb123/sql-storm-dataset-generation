SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    JSON_AGG(DISTINCT mi.info) AS movie_infos
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    a.name IS NOT NULL
GROUP BY 
    t.title, a.name, ct.kind
ORDER BY 
    num_companies DESC, num_keywords DESC
LIMIT 100;
