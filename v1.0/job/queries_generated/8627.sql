SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    COUNT(DISTINCT mc.company_id) AS company_count, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
    YEAR(t.production_year) AS release_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND c.kind = 'actor'
GROUP BY 
    a.name, t.title, c.kind, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    release_year DESC, actor_name ASC;
