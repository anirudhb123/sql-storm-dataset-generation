SELECT 
    t.title, 
    a.name AS actor_name, 
    cc.company_name AS company_name, 
    kt.keyword AS keyword
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cc ON mc.company_id = cc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year = 2023
ORDER BY 
    t.title, a.name;
