SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    mc.company_name AS production_company, 
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords, 
    ti.info AS additional_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000 
    AND ci.nr_order <= 5 
    AND cn.country_code = 'USA'
GROUP BY 
    t.title, a.name, c.kind, mc.company_name, ti.info
ORDER BY 
    t.title, a.name;
