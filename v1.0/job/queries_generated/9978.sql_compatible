
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    mc.note AS company_note,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    it.info = 'budget'
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, 
    t.title, 
    ct.kind, 
    mc.note, 
    mi.info, 
    t.production_year
ORDER BY 
    t.production_year DESC, 
    actor_name;
