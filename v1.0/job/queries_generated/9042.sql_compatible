
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT c.kind, ',') AS company_types,
    COUNT(DISTINCT mki.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword mki ON mk.keyword_id = mki.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mki.keyword) > 3
ORDER BY 
    t.production_year DESC, a.name ASC;
