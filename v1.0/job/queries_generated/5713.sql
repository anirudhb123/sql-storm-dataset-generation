SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS character_role, 
    p.info AS person_info, 
    tc.kind AS company_type 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    title AS t ON c.movie_id = t.id 
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id 
JOIN 
    person_info AS p ON a.person_id = p.person_id 
JOIN 
    info_type AS it ON p.info_type_id = it.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
AND 
    c.nr_order <= 5 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
