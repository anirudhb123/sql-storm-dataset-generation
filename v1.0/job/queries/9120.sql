
SELECT 
    t.title AS movie_title, 
    n.name AS actor_name, 
    a.name AS aka_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    name n ON a.person_id = n.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000 
    AND n.gender = 'M'
GROUP BY 
    t.title, n.name, a.name, m.info
HAVING 
    COUNT(DISTINCT k.keyword) > 1
ORDER BY 
    movie_title ASC, actor_name ASC;
