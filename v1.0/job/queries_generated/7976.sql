SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    COALESCE(m.info, 'No Info') AS movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_info AS m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    t.production_year DESC, actor_name;
