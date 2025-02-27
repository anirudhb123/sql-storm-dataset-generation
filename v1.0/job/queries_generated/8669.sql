SELECT 
    t.title, 
    a.name AS actor_name, 
    c.nr_order, 
    COALESCE(ci.kind, 'Unknown') AS company_type, 
    k.keyword, 
    mi.info 
FROM 
    title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ci ON mc.company_type_id = ci.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ci.kind IS NOT NULL 
    AND a.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    c.nr_order ASC 
LIMIT 100;
