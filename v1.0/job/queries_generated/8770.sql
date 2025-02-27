SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role,
    m.production_year,
    group_concat(k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND cn.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
