SELECT 
    t.title,
    ak.name AS actor_name,
    ci.note AS role_note,
    ci.nr_order AS role_order,
    c.name AS company_name,
    m.info AS movie_info,
    kw.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN 
    cast_info ci ON ak_t.id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, ak.name;
