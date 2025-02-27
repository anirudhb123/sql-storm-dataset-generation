SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    COUNT(m.id) AS movie_count
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year > 2000 
    AND k.keyword ILIKE '%action%' 
GROUP BY 
    a.name, t.title, p.info, c.kind, k.keyword 
ORDER BY 
    movie_count DESC 
LIMIT 50;
