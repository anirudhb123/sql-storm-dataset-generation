
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS company_type,
    STRING_AGG(DISTINCT p.info, ', ') AS person_info,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND c.kind = 'Production'
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY 
    movie_title ASC, actor_name DESC
LIMIT 50;
