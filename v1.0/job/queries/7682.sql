
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type,
    mi.info AS movie_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
AND 
    c.kind IN ('Actor', 'Actress')
GROUP BY 
    a.name, t.title, c.kind, mi.info
ORDER BY 
    MAX(t.production_year) DESC, a.name;
