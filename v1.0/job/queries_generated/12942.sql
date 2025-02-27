SELECT 
    t.title, 
    a.name AS actor_name, 
    ci.note AS character_note, 
    ckt.kind AS company_type, 
    mi.info AS movie_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ckt ON mc.company_type_id = ckt.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year ASC, a.name ASC;
