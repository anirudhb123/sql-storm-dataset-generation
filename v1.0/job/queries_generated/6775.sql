SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    ki.keyword AS movie_keyword,
    COUNT(DISTINCT ci.person_role_id) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    name p ON ci.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000 
    AND c.kind = 'Production'
GROUP BY 
    a.name, t.title, p.name, c.kind, ki.keyword
ORDER BY 
    role_count DESC, t.title ASC;
