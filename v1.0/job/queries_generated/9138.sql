SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT ci.id) AS cast_size,
    COUNT(DISTINCT pi.id) AS person_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type tc ON mc.company_type_id = tc.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
AND 
    tc.kind = 'Production'
GROUP BY 
    a.id, t.id, tc.id
ORDER BY 
    COUNT(DISTINCT ci.id) DESC, t.production_year DESC
LIMIT 50;
