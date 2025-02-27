SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    m.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
    COUNT(DISTINCT c.person_role_id) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year BETWEEN 1990 AND 2020
    AND a.imdb_index IS NOT NULL
GROUP BY 
    a.name, 
    m.title, 
    m.production_year
ORDER BY 
    role_count DESC, 
    m.production_year DESC 
LIMIT 100;
