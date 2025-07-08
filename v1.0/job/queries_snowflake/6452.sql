SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(mc.id) AS company_count
FROM 
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2020
    AND c.kind LIKE 'Production%'
GROUP BY 
    p.name, t.title, c.kind, k.keyword
ORDER BY 
    company_count DESC, t.title ASC;
