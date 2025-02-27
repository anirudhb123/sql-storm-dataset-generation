SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    m.production_year AS production_year,
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, k.keyword, p.info, m.production_year
ORDER BY 
    movie_count DESC, t.production_year ASC;
