
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS associated_keyword,
    COUNT(DISTINCT ci.movie_id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND c.kind LIKE 'Distributor%'
GROUP BY 
    a.name, t.title, c.kind, k.keyword
HAVING 
    COUNT(DISTINCT ci.movie_id) > 1
ORDER BY 
    total_movies DESC;
