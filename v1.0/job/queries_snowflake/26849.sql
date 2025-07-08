
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    LISTAGG(DISTINCT k.keyword, ', ' ) WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT c.kind, ', ' ) WITHIN GROUP (ORDER BY c.kind) AS company_types
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name;
