SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id AS role_id,
    co.name AS company_name,
    kw.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, t.title;
