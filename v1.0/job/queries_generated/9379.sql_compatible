
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names,
    p.info AS person_info
FROM 
    cast_info ci
INNER JOIN 
    aka_name a ON ci.person_id = a.person_id
INNER JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND (c.country_code = 'USA' OR c.country_code IS NULL)
GROUP BY 
    a.name, t.title, t.production_year, p.info
ORDER BY 
    t.production_year DESC, a.name;
