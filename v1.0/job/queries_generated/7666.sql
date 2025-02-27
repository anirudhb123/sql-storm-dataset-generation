SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type,
    m.company_id AS production_company,
    COUNT(k.id) AS keyword_count
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND m.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, m.company_id
ORDER BY 
    keyword_count DESC, actor_name ASC;
