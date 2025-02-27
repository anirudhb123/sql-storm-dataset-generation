SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS casting_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS companies
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    title tt ON tt.id = t.id
JOIN 
    movie_info mi ON tt.id = mi.movie_id
WHERE 
    tt.production_year >= 2000
    AND c.kind LIKE 'Actor%'
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
