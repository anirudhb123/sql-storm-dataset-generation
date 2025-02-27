SELECT 
    t.title, 
    a.name as actor_name, 
    c.kind as company_type, 
    k.keyword, 
    m.info 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info m ON t.id = m.movie_id 
WHERE 
    t.production_year > 2000 
    AND c.country_code = 'USA' 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
