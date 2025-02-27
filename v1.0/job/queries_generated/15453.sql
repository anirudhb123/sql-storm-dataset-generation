SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mt.info AS movie_info
FROM 
    aka_title at
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mt ON at.id = mt.movie_id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC;
