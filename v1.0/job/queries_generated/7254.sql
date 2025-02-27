SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    cc.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MIN(mi.info) AS earliest_release_date
FROM 
    cast_info c
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    comp_cast_type cc ON c.person_role_id = cc.id
WHERE 
    t.production_year > 2000 
    AND ct.kind = 'Production'
GROUP BY 
    n.name, t.title, c.role_id, cc.kind
ORDER BY 
    keyword_count DESC, earliest_release_date ASC
LIMIT 100;
