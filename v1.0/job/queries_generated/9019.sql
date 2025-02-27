SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(COALESCE(mi.info, 'N/A')) AS movie_info,
    t.production_year AS release_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    title t ON m.id = t.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, m.title, c.kind, t.production_year
ORDER BY 
    keyword_count DESC, release_year DESC;
