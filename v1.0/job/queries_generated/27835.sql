SELECT 
    t.title AS movie_title,
    ak.name AS aka_name,
    c.name AS character_name,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cmp.name AS company_name,
    cnt.kind AS company_type,
    r.role AS person_role
FROM 
    title t
JOIN 
    aka_title ak ON ak.movie_id = t.id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    name n ON n.id = ci.person_id
JOIN 
    char_name c ON c.imdb_id = n.imdb_id
JOIN 
    person_info p ON p.person_id = n.id 
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cmp ON cmp.id = mc.company_id
JOIN 
    company_type cnt ON cnt.id = mc.company_type_id
JOIN 
    role_type r ON r.id = ci.role_id
WHERE 
    t.production_year >= 2000 
    AND ak.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    AND k.keyword IN ('action', 'drama', 'comedy')
ORDER BY 
    t.title, ak.name, n.name
LIMIT 100;
