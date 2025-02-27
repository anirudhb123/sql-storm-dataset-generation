SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS role_type,
    t.production_year AS release_year,
    c.name AS company_name
FROM 
    aka_name ak
INNER JOIN 
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN 
    aka_title at ON ci.movie_id = at.movie_id
INNER JOIN 
    role_type rt ON ci.role_id = rt.id
INNER JOIN 
    movie_companies mc ON at.movie_id = mc.movie_id
INNER JOIN 
    company_name c ON mc.company_id = c.id
INNER JOIN 
    kind_type kt ON at.kind_id = kt.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC, ak.name;
