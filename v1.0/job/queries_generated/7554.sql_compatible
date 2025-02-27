
SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    STRING_AGG(k.keyword, ', ') AS keywords,
    ci.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS companies_involved,
    COUNT(DISTINCT mi.info_type_id) AS info_count,
    COUNT(DISTINCT c.role_id) AS unique_roles
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ci.kind = 'Distributor'
GROUP BY 
    t.title, p.name, ci.kind
ORDER BY 
    t.title, p.name;
