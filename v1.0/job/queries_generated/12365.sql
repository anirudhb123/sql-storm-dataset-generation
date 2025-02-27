SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    cast_info c_info ON ak_t.id = c_info.movie_id
JOIN 
    aka_name ak ON c_info.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
