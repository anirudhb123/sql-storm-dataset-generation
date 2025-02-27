SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    tk.keyword AS movie_keyword,
    COUNT(DISTINCT p.id) AS total_movies,
    AVG(mi.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword tk ON mk.keyword_id = tk.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind, co.name, tk.keyword
HAVING 
    COUNT(DISTINCT p.id) > 3
ORDER BY 
    total_movies DESC, avg_production_year ASC;
