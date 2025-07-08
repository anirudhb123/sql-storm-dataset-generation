SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    k.keyword AS movie_keyword,
    cc.kind AS company_type,
    mi.info AS movie_info_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type cc ON mc.company_type_id = cc.id
JOIN 
    complete_cast cc2 ON t.id = cc2.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND cc.kind = 'production'
ORDER BY 
    t.production_year DESC, a.name ASC;
