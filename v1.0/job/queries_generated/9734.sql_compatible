
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    m.info AS additional_info,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' ORDER BY id LIMIT 1)
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'documentary'))
GROUP BY 
    a.name, t.title, c.kind, m.info, p.info
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    actor_name, movie_title;
