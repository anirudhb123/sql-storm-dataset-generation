SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type,
    r.role AS role_description
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
    movie_info mi ON t.id = mi.movie_id
WHERE 
    m.production_year > 2000
    AND r.role IN ('Actor', 'Director')
GROUP BY 
    a.name, t.title, m.production_year, c.kind, r.role
ORDER BY 
    production_year DESC, actor_name;
