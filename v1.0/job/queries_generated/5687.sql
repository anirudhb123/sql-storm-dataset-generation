SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cnt.name AS company_name,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
WHERE 
    m.production_year > 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, m.title, c.kind, p.info, k.keyword, cnt.name
ORDER BY 
    movie_count DESC;
