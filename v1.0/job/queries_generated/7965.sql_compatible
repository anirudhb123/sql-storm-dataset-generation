
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ',') AS movie_keywords,
    c.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS production_companies
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
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT k.keyword) > 2
ORDER BY 
    t.production_year DESC, actor_name;
