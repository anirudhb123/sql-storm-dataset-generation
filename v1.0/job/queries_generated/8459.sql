SELECT 
    ak.name AS actor_name,
    mov.title AS movie_title,
    mov.production_year AS production_year,
    grp.kind AS company_type,
    grp.name AS company_name,
    kw.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title mov ON ci.movie_id = mov.id
JOIN 
    movie_companies mc ON mov.id = mc.movie_id
JOIN 
    company_name grp ON mc.company_id = grp.id
JOIN 
    movie_keyword mk ON mov.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mov.production_year >= 2000
    AND ak.name IS NOT NULL
ORDER BY 
    mov.production_year DESC, 
    ak.name ASC, 
    mov.title ASC
LIMIT 100;
