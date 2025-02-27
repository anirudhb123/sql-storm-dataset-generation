SELECT 
    ak.id AS aka_id,
    ak.name AS aka_name,
    t.title AS movie_title,
    c.kind AS company_type,
    AVG(CASE WHEN m.production_year >= 2000 THEN m.production_year ELSE NULL END) AS avg_production_year,
    COUNT(DISTINCT k.keyword) AS unique_keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND t.id IS NOT NULL
    AND ci.note IS NULL
GROUP BY 
    ak.id, ak.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    avg_production_year DESC, unique_keywords DESC
LIMIT 100;
