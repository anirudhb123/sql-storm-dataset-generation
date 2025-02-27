
SELECT 
    a.id AS actor_id, 
    a.name AS actor_name, 
    t.id AS title_id, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT k.keyword) AS keywords, 
    STRING_AGG(DISTINCT c.kind) AS company_types
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND a.name LIKE 'A%' 
GROUP BY 
    a.id, a.name, t.id, t.title, t.production_year 
ORDER BY 
    t.production_year DESC, a.name;
