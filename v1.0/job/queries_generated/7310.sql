SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_kind, 
    COALESCE(mi.info, 'No info available') AS movie_info, 
    cn.name AS company_name, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
