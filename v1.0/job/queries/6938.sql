SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    p.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000 
    AND a.name ILIKE '%Smith%'
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
ORDER BY 
    t.production_year DESC, a.name;
