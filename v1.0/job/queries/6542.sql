SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    c.kind AS company_type,
    n.gender AS actor_gender,
    COUNT(k.keyword) AS keyword_count
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
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name n ON a.person_id = n.imdb_id
WHERE 
    t.production_year >= 2000
    AND c.kind LIKE '%Production%'
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind, n.gender
ORDER BY 
    keyword_count DESC, t.production_year DESC;
