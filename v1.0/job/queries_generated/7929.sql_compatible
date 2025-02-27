
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    STRING_AGG(DISTINCT c.name, ', ') AS companies
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000
    AND (c.country_code = 'USA' OR c.country_code IS NULL)
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
