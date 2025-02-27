SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT p.id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT p.id) > 1
ORDER BY 
    actor_name, movie_title;
