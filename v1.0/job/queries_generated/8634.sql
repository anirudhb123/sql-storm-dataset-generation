SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
AND 
    m.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(DISTINCT kw.id) > 2
ORDER BY 
    m.production_year DESC;
