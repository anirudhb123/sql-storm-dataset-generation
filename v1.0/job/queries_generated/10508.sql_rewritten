SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    c.kind LIKE '%Production%'
    AND t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;