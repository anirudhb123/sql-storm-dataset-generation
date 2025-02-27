SELECT 
    a.name AS actor_name,
    a.id AS actor_id,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
    COUNT(m.id) AS company_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.id, t.title, t.production_year, c.kind
HAVING 
    COUNT(m.id) > 0
ORDER BY 
    t.production_year DESC, actor_name;
