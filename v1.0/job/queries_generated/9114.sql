SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    np.name AS person_info_name,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    name np ON a.person_id = np.imdb_id
WHERE 
    t.production_year IN (2020, 2021, 2022)
    AND c.kind IN ('Distributor', 'Production')
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    t.title ASC
LIMIT 100;
