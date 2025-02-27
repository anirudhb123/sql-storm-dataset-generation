SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.name AS production_company,
    kw.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year >= 2000 
    AND r.role IN ('Actor', 'Actress')
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
