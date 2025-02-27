SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_role_id,
    rc.role AS role_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    COUNT(DISTINCT pi.info_id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rc ON ci.role_id = rc.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    a.id, a.name, t.id, t.title, ci.person_role_id, rc.role
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 AND COUNT(DISTINCT mk.keyword_id) > 5
ORDER BY 
    t.production_year DESC, a.name ASC;
