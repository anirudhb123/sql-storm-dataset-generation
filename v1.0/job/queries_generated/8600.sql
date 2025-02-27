SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword, 
    mp.info AS movie_info
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
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
    movie_info mp ON t.id = mp.movie_id
WHERE 
    t.production_year > 2000
    AND c.kind LIKE 'Production%'
    AND k.keyword IS NOT NULL
ORDER BY 
    t.title, a.name;
