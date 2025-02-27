SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON at.id = mi.movie_id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    at.production_year >= 2000
ORDER BY 
    at.production_year DESC, ak.name ASC;
