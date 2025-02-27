SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    cn.name AS company_name,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
GROUP BY 
    a.name, t.title, c.kind, cn.name, m.production_year, pi.info
ORDER BY 
    m.production_year DESC, a.name;
