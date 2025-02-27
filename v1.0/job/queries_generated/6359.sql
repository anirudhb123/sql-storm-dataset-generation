SELECT 
    a.name AS actor_name,
    a.imdb_index AS actor_imdb_index,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    ct.kind AS cast_type,
    COUNT(*) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    comp_cast_type c ON cc.subject_id = c.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
    AND c.kind LIKE 'Full Cast%'
GROUP BY 
    a.name, a.imdb_index, t.title, t.production_year, c.kind, ct.kind
ORDER BY 
    total_movies DESC
LIMIT 10;
