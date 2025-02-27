SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    m.production_year >= 2000
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year, c.kind
HAVING 
    COUNT(DISTINCT k.id) > 1
ORDER BY 
    m.production_year DESC, a.name;
