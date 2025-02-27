SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.title IS NOT NULL
    AND p.info IS NOT NULL
    AND c.kind IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC;
