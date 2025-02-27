SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
AND 
    k.keyword IS NOT NULL
ORDER BY 
    ak.name, t.production_year DESC, c.kind
LIMIT 100;
