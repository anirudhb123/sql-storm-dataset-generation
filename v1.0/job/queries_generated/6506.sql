SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    cn.name AS company_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 1990 AND 2020
GROUP BY 
    a.name, t.title, t.production_year, ct.kind, cn.name
ORDER BY 
    keyword_count DESC, t.production_year ASC;
