EXPLAIN ANALYZE 
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_type, 
    mci.company_name AS company_name,
    m.production_year AS production_year
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name mci ON mc.company_id = mci.id
JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
ORDER BY 
    a.name, t.production_year DESC
LIMIT 100;
