SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    c.note AS role_note, 
    m.info AS movie_info,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2022
AND 
    a.name IS NOT NULL
AND 
    c.nr_order IS NOT NULL
GROUP BY 
    a.name, t.title, c.nr_order, m.info
ORDER BY 
    a.name, t.title;
