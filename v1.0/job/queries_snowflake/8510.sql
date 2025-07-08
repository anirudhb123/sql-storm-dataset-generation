SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.kind AS company_type, 
    p.info AS person_info, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title m ON ci.movie_id = m.id 
JOIN 
    movie_companies mc ON m.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    movie_keyword mk ON m.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    m.production_year BETWEEN 2000 AND 2023 
    AND c.kind LIKE '%Production%' 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards') 
ORDER BY 
    m.production_year DESC, 
    a.name;
