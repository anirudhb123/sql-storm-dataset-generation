SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    k.keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    pi.info AS person_info,
    rt.role AS role_type,
    COUNT(DISTINCT mc.movie_id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.nr_order, k.keyword, cn.name, ct.kind, pi.info, rt.role
ORDER BY 
    movie_count DESC, t.production_year ASC;
