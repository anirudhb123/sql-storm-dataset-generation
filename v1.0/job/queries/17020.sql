SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    ci.nr_order AS role_order,
    rt.role AS role_title
FROM 
    title AS t
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS p ON ci.person_id = p.person_id
JOIN 
    role_type AS rt ON ci.role_id = rt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    ci.nr_order ASC;
