SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    c.name AS company_name,
    COUNT(DISTINCT mc.company_id) AS number_of_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    a.name, t.title, t.production_year, c.name, ct.kind
ORDER BY 
    t.production_year DESC, a.name;
