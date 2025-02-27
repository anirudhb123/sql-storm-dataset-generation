
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    STRING_AGG(DISTINCT c.name, ',') AS companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year >= 2000 AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
