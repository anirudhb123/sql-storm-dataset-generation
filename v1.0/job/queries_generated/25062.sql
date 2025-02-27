SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_role,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c2.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT pi.info, '; ') AS person_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c2 ON c2.id = mc.company_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, movie_title;
