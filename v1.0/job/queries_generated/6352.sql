SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS role_description,
    COUNT(DISTINCT p.id) AS total_people_involved
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
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    t.production_year >= 2000
    AND c.kind IN ('Production', 'Distribution')
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, t.production_year, c.kind, k.keyword, r.role
ORDER BY 
    total_people_involved DESC;
