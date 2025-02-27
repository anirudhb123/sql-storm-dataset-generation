SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year AS year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    c.kind AS company_type
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
GROUP BY 
    a.id, t.id, c.id
ORDER BY 
    year DESC, actor_name;
