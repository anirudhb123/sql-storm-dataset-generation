SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    p.gender AS actor_gender,
    COUNT(DISTINCT c.id) AS total_roles,
    STRING_AGG(DISTINCT r.role, ', ') AS roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON a.person_id = p.imdb_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND (LOWER(t.title) LIKE '%action%' OR LOWER(t.title) LIKE '%drama%')
GROUP BY 
    a.name, t.title, t.production_year, p.gender
ORDER BY 
    total_roles DESC, t.production_year DESC
LIMIT 50;
