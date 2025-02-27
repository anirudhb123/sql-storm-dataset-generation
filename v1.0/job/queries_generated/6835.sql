SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS casting_type, 
    m.production_year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office') 
GROUP BY 
    a.name, t.title, c.kind, m.production_year 
ORDER BY 
    m.production_year DESC, a.name ASC;
