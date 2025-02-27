SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rc.role AS role,
    mt.kind AS company_type,
    mt.production_year AS production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type rc ON ci.role_id = rc.id
WHERE 
    ct.kind = 'Distributor'
ORDER BY 
    mt.production_year DESC, 
    t.title ASC;
