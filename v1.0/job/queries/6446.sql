SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
    AND c.kind = 'actor'
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(k.keyword) > 5
ORDER BY 
    t.production_year DESC, a.name;
