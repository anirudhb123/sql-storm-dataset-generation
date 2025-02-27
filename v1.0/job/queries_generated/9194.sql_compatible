
SELECT 
    p.name AS actor_name, 
    m.title AS movie_title, 
    m.production_year, 
    c.nr_order, 
    ct.kind AS cast_type, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords 
FROM 
    cast_info c 
JOIN 
    aka_name p ON c.person_id = p.person_id 
JOIN 
    aka_title m ON c.movie_id = m.movie_id 
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id 
JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    m.production_year >= 2000 
    AND ct.kind = 'actor' 
GROUP BY 
    p.name, m.title, m.production_year, c.nr_order, ct.kind 
ORDER BY 
    m.production_year DESC, p.name ASC;
