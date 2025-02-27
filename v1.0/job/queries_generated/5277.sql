SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT s.name SEPARATOR ', ') AS supporting_actors,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    MIN(mi.info) AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND ci.nr_order < 3
GROUP BY 
    t.title, a.name, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT a.id) > 1
ORDER BY 
    t.production_year DESC;
