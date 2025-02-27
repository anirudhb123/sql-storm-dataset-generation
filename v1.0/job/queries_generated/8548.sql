SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    p.info AS actor_info, 
    k.keyword AS movie_keyword,
    GROUP_CONCAT(c.note) AS cast_notes
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, c.kind, p.info, k.keyword
ORDER BY 
    t.production_year DESC, a.name ASC;
