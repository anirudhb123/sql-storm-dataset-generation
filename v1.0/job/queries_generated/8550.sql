SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    GROUP_CONCAT(cast_info.note) AS cast_notes
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'biography')
    AND r.role LIKE '%lead%'
GROUP BY 
    a.name, t.title, c.kind, p.info, k.keyword
ORDER BY 
    a.name, t.title;
