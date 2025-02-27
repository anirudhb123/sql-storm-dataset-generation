SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 3
ORDER BY 
    m.production_year DESC, actor_name;
