SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    c.nr_order, 
    c.note AS role_note, 
    co.name AS company_name, 
    k.keyword AS movie_keyword, 
    m.info AS movie_info 
FROM 
    aka_name AS a 
JOIN 
    cast_info AS c ON a.person_id = c.person_id 
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id 
JOIN 
    company_name AS co ON mc.company_id = co.id 
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id 
JOIN 
    keyword AS k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info AS m ON t.id = m.movie_id 
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
    AND k.keyword IN ('Action', 'Drama') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    t.title ASC 
LIMIT 100;
