SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cp.name, ', ') AS company_names
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
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind = 'actor'
GROUP BY 
    a.name, t.title, c.kind, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
