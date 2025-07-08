SELECT 
    tn.title, 
    ak.name AS actor_name, 
    ct.kind AS cast_type
FROM 
    title tn
JOIN 
    movie_companies mc ON tn.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON tn.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    tn.production_year > 2000
ORDER BY 
    tn.production_year DESC;
