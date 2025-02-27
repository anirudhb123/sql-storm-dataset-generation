
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    m.production_year, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    title m ON t.id = m.id 
WHERE 
    m.production_year BETWEEN 2000 AND 2020 
    AND c.kind = 'actor' 
GROUP BY 
    a.name, t.title, c.kind, m.production_year 
ORDER BY 
    m.production_year DESC, a.name;
