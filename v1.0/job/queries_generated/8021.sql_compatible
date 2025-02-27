
SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    COUNT(DISTINCT pi.info) AS info_count
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IN ('Actor', 'Actress')
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(DISTINCT pi.info) > 0
ORDER BY 
    t.title, a.name;
