SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    comp.name AS company_name,
    year(t.production_year) AS production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND comp.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, comp.name, t.production_year
ORDER BY 
    production_year DESC, a.name;
