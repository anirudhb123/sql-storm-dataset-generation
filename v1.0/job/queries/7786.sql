SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.name AS company_name,
    kt.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000 AND 
    kt.keyword LIKE '%Drama%' AND 
    i.info LIKE '%Award%'
ORDER BY 
    t.production_year DESC, 
    a.name;
