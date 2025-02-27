
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.info AS movie_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000 
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    actor_name, movie_title;
