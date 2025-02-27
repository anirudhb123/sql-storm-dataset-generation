SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mk.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    aka_name ak ON ak_t.id = ak.id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.title, ak.name;
