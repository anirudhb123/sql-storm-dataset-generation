SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.note AS cast_note,
    co.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name ILIKE '%Smith%'
AND 
    kt.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
