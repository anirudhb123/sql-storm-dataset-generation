SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS actor_role,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    cast_info ci
INNER JOIN 
    aka_name a ON ci.person_id = a.person_id
INNER JOIN 
    title t ON ci.movie_id = t.id
INNER JOIN 
    role_type r ON ci.role_id = r.id
INNER JOIN 
    movie_companies mc ON t.id = mc.movie_id 
INNER JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind
ORDER BY 
    t.production_year DESC, a.name;
