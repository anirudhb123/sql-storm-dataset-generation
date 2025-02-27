SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(k.id) AS keyword_count,
    COALESCE(MIN(mi.info), 'No info available') AS movie_info,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, ct.kind
HAVING 
    COUNT(DISTINCT k.id) > 3
ORDER BY 
    keyword_count DESC, movie_title ASC;
