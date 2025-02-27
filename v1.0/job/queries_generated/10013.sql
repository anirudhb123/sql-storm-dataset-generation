-- Performance Benchmark Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.note AS role_note,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
GROUP BY 
    t.id, a.id, mi.info_type_id
ORDER BY 
    m.production_year DESC, t.title;
