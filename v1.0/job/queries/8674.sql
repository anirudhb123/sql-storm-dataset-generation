SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_description,
    tc.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name an
JOIN 
    cast_info c ON an.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type tc ON mc.company_type_id = tc.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    name n ON an.person_id = n.imdb_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND tc.kind ILIKE 'production'
GROUP BY 
    n.name, t.title, c.note, tc.kind
ORDER BY 
    total_movies DESC, actor_name ASC;
