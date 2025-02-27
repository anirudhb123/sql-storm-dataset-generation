SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    d.info AS movie_info,
    s.info AS person_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info d ON t.id = d.movie_id
LEFT JOIN 
    person_info s ON a.person_id = s.person_id
LEFT JOIN 
    movie_keyword k ON t.id = k.movie_id
WHERE 
    t.production_year > 2000 
    AND d.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Awards'))
    AND a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
