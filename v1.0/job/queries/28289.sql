SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(c.id) AS total_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
    ARRAY_AGG(DISTINCT cn.name) AS companies_involved
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year >= 2000
GROUP BY 
    a.name, m.title, m.production_year
ORDER BY 
    total_roles DESC, m.production_year DESC
LIMIT 50;
