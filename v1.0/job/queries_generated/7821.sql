SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_info,
    COUNT(k.id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    c.name AS company_name,
    ct.kind AS company_type,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, p.info, c.name, ct.kind, r.role
ORDER BY 
    t.production_year DESC, actor_name;
