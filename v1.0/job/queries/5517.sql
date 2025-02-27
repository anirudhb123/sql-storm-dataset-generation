
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS company_name,
    r.role AS role_type
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year > 2000
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name ASC;
