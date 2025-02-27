
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.person_role_id AS role_id,
    ct.kind AS comp_cast_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT co.name, ', ') AS companies,
    MAX(mi.info) AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND ci.person_role_id IS NOT NULL
GROUP BY 
    t.title, a.name, ci.person_role_id, ct.kind
ORDER BY 
    t.title, a.name;
