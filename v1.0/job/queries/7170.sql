
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    ct.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND ct.kind LIKE 'Producer%'
GROUP BY 
    a.name, t.title, t.production_year, r.role, ct.kind
ORDER BY 
    keyword_count DESC, t.production_year DESC;
