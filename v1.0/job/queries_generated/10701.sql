-- Example SQL query for performance benchmarking using the provided schema

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    ni.info AS additional_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
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
    info_type ni ON mi.info_type_id = ni.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, t.title;
