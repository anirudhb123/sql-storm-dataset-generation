SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    tc.kind AS title_kind,
    m.info AS movie_description,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    kind_type tc ON t.kind_id = tc.id
JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, tc.kind, m.info
ORDER BY 
    a.name, t.production_year DESC;
