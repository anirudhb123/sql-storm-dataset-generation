SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT k.id) AS keyword_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    t.production_year > 2000 
    AND r.role LIKE '%actor%'
GROUP BY 
    t.title, a.name, c.kind, p.info, co.name
ORDER BY 
    keyword_count DESC, movie_title ASC;
