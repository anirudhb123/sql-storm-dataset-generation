SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    COUNT(mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year > 2000
    AND c.nr_order < 5
GROUP BY 
    a.name, t.title, t.production_year, c.role_id
ORDER BY 
    keyword_count DESC, t.production_year DESC;
