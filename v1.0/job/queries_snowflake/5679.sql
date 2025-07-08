
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    cc.kind AS cast_type,
    ct.kind AS company_type,
    COUNT(mk.id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.role_id, cc.kind, ct.kind
HAVING 
    COUNT(mk.id) > 5
ORDER BY 
    actor_name ASC, movie_title ASC;
