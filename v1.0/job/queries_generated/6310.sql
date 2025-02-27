SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(k.keyword) AS keywords,
    GROUP_CONCAT(ci.note) AS cast_notes,
    ci.nr_order AS casting_order,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IN ('Actor', 'Director')
GROUP BY 
    a.name, t.title, c.kind, ci.nr_order, m.info
ORDER BY 
    t.production_year DESC, a.name ASC;
