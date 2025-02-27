SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS role_note,
    p.info AS person_info,
    ckt.kind AS company_type
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ckt ON mc.company_type_id = ckt.id
JOIN 
    person_info AS p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
    AND ci.nr_order < 5
ORDER BY 
    t.production_year DESC, 
    a.name;
