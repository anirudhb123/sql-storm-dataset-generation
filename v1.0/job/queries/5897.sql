
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT p.info) AS personal_info_count
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
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Distributor'
GROUP BY 
    a.name, t.title, ct.kind
ORDER BY 
    keyword_count DESC, personal_info_count DESC;
