SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    keyword AS k ON t.id = k.id
JOIN 
    movie_info AS ti ON t.id = ti.movie_id
WHERE 
    t.production_year > 2000 
    AND ct.kind = 'Distributor'
    AND k.keyword IN ('Adventure', 'Action')
ORDER BY 
    t.production_year DESC, a.name ASC;
