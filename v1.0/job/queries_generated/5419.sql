SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_role,
    co.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
