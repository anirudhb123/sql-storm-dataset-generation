SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS company_type, 
    COUNT(DISTINCT m.id) AS multiple_movies
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND k.keyword IN ('Drama', 'Action', 'Comedy')
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT t.id) > 1
ORDER BY 
    multiple_movies DESC, actor_name ASC;
