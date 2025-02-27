-- This SQL query retrieves the titles of movies along with the names of the people who acted in them, 
-- allowing for performance benchmarking of join operations.

SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS character_role
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    ak.name;
