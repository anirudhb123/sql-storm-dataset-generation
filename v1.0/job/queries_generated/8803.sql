SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COALESCE(MIN(m.info_type_id), 'No Info') AS first_info_type_id,
    MAX(m.production_year) AS latest_movie_year
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
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT k.id) > 3
ORDER BY 
    latest_movie_year DESC, actor_name ASC
LIMIT 
    50;
