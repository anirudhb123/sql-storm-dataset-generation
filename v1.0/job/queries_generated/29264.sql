SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    cc.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ARRAY_AGG(DISTINCT pi.info) AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type cc ON ci.person_role_id = cc.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, cc.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_name, movie_title;
