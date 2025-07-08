
SELECT 
    an.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    COUNT(*) AS total_casts
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
GROUP BY 
    an.name, t.title, c.kind, co.name, k.keyword, m.info
ORDER BY 
    total_casts DESC
LIMIT 50;
