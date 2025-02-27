
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    STRING_AGG(DISTINCT comp.name, ',') AS companies,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year >= 2000
GROUP BY 
    a.name, m.title, c.kind
ORDER BY 
    movie_count DESC, actor_name ASC;
