
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS cast_type,
    COUNT(m.movie_id) AS total_movies,
    SUM(CASE WHEN m.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_info
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    company_name cp ON m.movie_id = cp.imdb_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id 
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 1990 AND 2020 
GROUP BY 
    a.name, t.title, ct.kind 
ORDER BY 
    total_movies DESC, movies_with_info DESC 
LIMIT 50;
