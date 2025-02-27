SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    k.keyword AS associated_keyword, 
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.name, t.title, c.nr_order, k.keyword
HAVING 
    COUNT(DISTINCT cn.id) > 1
ORDER BY 
    a.name, t.title;
