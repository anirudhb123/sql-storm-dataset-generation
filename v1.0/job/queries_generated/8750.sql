SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    ci.note AS role_description,
    c.name AS company_name,
    it.info AS additional_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    info_type AS it ON mi.info_type_id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ci.nr_order <= 3
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name;
