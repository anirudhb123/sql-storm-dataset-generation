SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    y.production_year, 
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title y ON t.movie_id = y.id
WHERE 
    y.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind, y.production_year
HAVING 
    COUNT(DISTINCT k.keyword) > 5
ORDER BY 
    y.production_year DESC, actor_name;
