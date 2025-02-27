
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ct.kind AS company_type,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.person_role_id) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year > 2000 AND 
    ct.kind LIKE 'Production%'
GROUP BY 
    a.name, t.title, ct.kind
HAVING 
    COUNT(DISTINCT kw.id) > 0
ORDER BY 
    role_count DESC, a.name ASC;
