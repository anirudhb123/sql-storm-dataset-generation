
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    r.role AS role_name,
    c.kind AS company_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    t.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE 'A%' 
    AND t.production_year >= 2000 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, r.role, c.kind, p.info, k.keyword, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
