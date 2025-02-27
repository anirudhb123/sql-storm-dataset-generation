SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    r.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    c.country_code = 'USA'
AND 
    m.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, c.kind, m.production_year, r.role
ORDER BY 
    m.production_year DESC, a.name;
