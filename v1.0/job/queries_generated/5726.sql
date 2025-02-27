SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_role,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MIN(m.production_year) AS earliest_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, earliest_production_year ASC
LIMIT 50;
