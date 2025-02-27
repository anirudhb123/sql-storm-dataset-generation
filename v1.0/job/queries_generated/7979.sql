SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_name,
    count(DISTINCT mk.keyword) AS keyword_count,
    c2.name AS production_company,
    r.role AS role_description
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year >= 2000 AND 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    t.title, a.name, c.kind, c2.name, r.role
ORDER BY 
    keyword_count DESC, movie_title ASC;
