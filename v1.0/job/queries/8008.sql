SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    cp.kind AS company_type,
    COUNT(c.id) AS character_count,
    k.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND cp.kind IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, cp.kind, k.keyword
HAVING 
    COUNT(c.id) > 1
ORDER BY 
    t.production_year DESC, actor_name ASC;
