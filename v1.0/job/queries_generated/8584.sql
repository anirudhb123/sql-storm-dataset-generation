SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS additional_info
FROM 
    aka_name p
JOIN 
    cast_info ci ON p.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id 
WHERE 
    p.name ILIKE '%Smith%' 
    AND t.production_year >= 2000 
    AND c.kind IS NOT NULL 
ORDER BY 
    t.production_year DESC, actor_name
LIMIT 50;
