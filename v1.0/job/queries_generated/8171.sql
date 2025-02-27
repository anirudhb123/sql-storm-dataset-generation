SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE NULL END) AS average_production_year
FROM 
    aka_title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    title mt ON t.id = mt.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    movie_count DESC, average_production_year ASC
LIMIT 100;
