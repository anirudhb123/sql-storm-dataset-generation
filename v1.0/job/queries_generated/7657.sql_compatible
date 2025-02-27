
SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS casting_types,
    COUNT(DISTINCT co.name) AS company_count
FROM 
    aka_name AS n
JOIN 
    cast_info AS ci ON n.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
AND 
    n.name IS NOT NULL
GROUP BY 
    n.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 1
ORDER BY 
    t.production_year DESC, actor_name ASC;
