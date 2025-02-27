SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS character_role,
    COUNT(DISTINCT mco.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_companies mco ON t.id = mco.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    production_year DESC, actor_name;
