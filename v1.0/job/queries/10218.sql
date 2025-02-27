SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    t.production_year 
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    title AS t ON m.id = t.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
