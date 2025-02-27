SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS company_type,
    COUNT(DISTINCT m.id) AS company_count,
    t.production_year,
    ki.keyword AS movie_keyword,
    pi.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    ct.kind IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.nr_order, ct.kind, t.production_year, ki.keyword, pi.info
ORDER BY 
    t.production_year DESC, actor_name;
