SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS actor_role_id,
    c.nr_order AS role_order,
    m.company_id AS production_company_id,
    cn.name AS production_company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies m ON cc.movie_id = m.movie_id
JOIN 
    company_name cn ON m.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
ORDER BY 
    a.name, t.title, c.nr_order;
