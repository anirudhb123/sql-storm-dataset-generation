
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS casting_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT m.company_id) AS number_of_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 1990 AND 2020
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    number_of_companies DESC, actor_name ASC;
