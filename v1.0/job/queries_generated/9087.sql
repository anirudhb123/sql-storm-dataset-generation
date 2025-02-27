SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS role_kind,
    k.keyword AS movie_keyword,
    ci.info AS company_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
JOIN 
    movie_companies mc ON mc.movie_id = m.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    kind_type k ON m.kind_id = k.id
JOIN 
    complete_cast cc ON cc.movie_id = m.id
JOIN 
    movie_keyword mk ON mk.movie_id = m.id
JOIN 
    keyword k2 ON mk.keyword_id = k2.id
JOIN 
    movie_info mi ON mi.movie_id = m.id
WHERE 
    a.name IS NOT NULL AND
    cn.country_code = 'USA' AND
    m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, 
    a.name ASC;
