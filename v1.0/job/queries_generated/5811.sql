SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order < 3
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%biography%')
GROUP BY 
    t.title, a.name, p.info, c.kind, k.keyword
ORDER BY 
    company_count DESC, t.title;
