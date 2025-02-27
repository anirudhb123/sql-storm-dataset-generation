SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id AS role_id,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    cast_info c ON c.movie_id = t.id
JOIN 
    aka_name ak ON ak.id = c.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
