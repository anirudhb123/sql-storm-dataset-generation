SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(*) AS appearances
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, t.title, c.kind, mi.info, k.keyword
HAVING 
    COUNT(*) > 1
ORDER BY 
    appearances DESC, a.name ASC;
