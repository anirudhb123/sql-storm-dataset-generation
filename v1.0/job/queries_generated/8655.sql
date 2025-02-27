SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year, c.kind
ORDER BY 
    m.production_year DESC,
    a.name;
