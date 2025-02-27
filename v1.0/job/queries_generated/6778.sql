SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS comp_cast_type,
    p.info AS person_info,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(m.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    title mt ON t.id = mt.id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    AND t.production_year > 2000
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, p.info
ORDER BY 
    avg_production_year DESC, keyword_count DESC
LIMIT 50;
