
SELECT 
    ak.name AS actor_name, 
    mv.title AS movie_title, 
    mv.production_year, 
    LISTAGG(DISTINCT kw.keyword, ', ') AS keywords,
    cmp.name AS company_name, 
    rt.role AS role_name
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title mv ON ci.movie_id = mv.id
JOIN 
    movie_companies mc ON mv.id = mc.movie_id
JOIN 
    company_name cmp ON mc.company_id = cmp.id
JOIN 
    movie_keyword mk ON mv.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    mv.production_year >= 2000
AND 
    cmp.country_code = 'USA'
GROUP BY 
    ak.name, mv.title, mv.production_year, cmp.name, rt.role
ORDER BY 
    mv.production_year DESC, ak.name;
