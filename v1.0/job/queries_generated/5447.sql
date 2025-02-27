SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.role_id,
    k.keyword
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
AND 
    k.keyword LIKE '%action%'
ORDER BY 
    m.production_year DESC, actor_name;
