SELECT 
    n.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    c.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.id
JOIN 
    movie_companies mc ON a.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.production_year BETWEEN 2000 AND 2020
    AND c.kind IS NOT NULL
GROUP BY 
    n.name, a.title, a.production_year, c.kind
ORDER BY 
    a.production_year DESC, actor_name;
