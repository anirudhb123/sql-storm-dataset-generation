SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_info
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
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
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND c.kind ILIKE 'production%' 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%budget%')
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    k.keyword ASC 
LIMIT 50;
