
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS cast_type,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year >= 2000
GROUP BY 
    a.name, m.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
