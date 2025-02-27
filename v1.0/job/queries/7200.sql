
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.kind AS cast_type,
    p.info AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    m.production_year >= 2000 
    AND a.name IS NOT NULL 
GROUP BY 
    a.name, m.title, m.production_year, c.kind, p.info
ORDER BY 
    m.production_year DESC, a.name ASC;
