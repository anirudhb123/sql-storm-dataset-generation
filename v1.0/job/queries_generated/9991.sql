SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    rt.role AS role_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type rt ON c.role_id = rt.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id 
GROUP BY 
    a.name, t.title, c.nr_order, rt.role 
ORDER BY 
    t.production_year DESC, c.nr_order ASC;
