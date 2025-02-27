
SELECT 
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    tp.role AS role_type
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    role_type tp ON ci.role_id = tp.id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
    AND a.name ILIKE '%Smith%'
GROUP BY 
    t.title, t.production_year, a.name, tp.role
ORDER BY 
    t.production_year DESC, COUNT(k.keyword) DESC;
