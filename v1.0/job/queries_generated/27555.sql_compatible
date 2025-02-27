
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ci.role_id AS role_id,
    COUNT(DISTINCT ci.id) AS num_cast_entries
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, ci.role_id
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    t.production_year DESC,
    num_cast_entries DESC;
