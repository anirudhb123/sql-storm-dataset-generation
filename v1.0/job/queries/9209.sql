
SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords,
    c.kind AS company_type,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    name n
JOIN 
    aka_name ak ON n.id = ak.person_id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    n.gender = 'F'
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    n.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    t.production_year DESC, actor_name;
