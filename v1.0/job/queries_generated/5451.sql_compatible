
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    p.info AS actor_info, 
    c.kind AS cast_kind,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
WHERE 
    t.production_year >= 2000 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') 
GROUP BY 
    a.name, t.title, p.info, c.kind 
ORDER BY 
    MAX(t.production_year) DESC, a.name ASC;
