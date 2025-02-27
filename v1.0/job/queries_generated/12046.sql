SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    it.info AS movie_info
FROM 
    aka_title AS t
JOIN 
    cast_info AS c ON t.id = c.movie_id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    info_type AS it ON mi.info_type_id = it.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
