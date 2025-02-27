SELECT 
    t.title, 
    ak.name AS actor_name, 
    cm.name AS company_name, 
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
ORDER BY 
    t.title, ak.name;