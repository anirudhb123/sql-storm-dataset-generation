SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    aka_name a ON a_t.id = a.id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    name n ON ci.person_id = n.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    keyword k ON k.id = mc.movie_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type i_t ON mi.info_type_id = i_t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, a.name;
