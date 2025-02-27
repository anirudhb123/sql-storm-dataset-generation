SELECT 
    at.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS role_type,
    ty.production_year,
    cn.name AS company_name
FROM 
    aka_title AS at
JOIN 
    cast_info AS ci ON at.id = ci.movie_id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN 
    role_type AS ct ON ci.role_id = ct.id
JOIN 
    movie_companies AS mc ON at.id = mc.movie_id
JOIN 
    company_name AS cn ON mc.company_id = cn.id
JOIN 
    title AS ty ON at.id = ty.id
WHERE 
    ty.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ty.production_year DESC, 
    at.title ASC;
