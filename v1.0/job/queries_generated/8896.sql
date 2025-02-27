SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    cp.name AS company_name,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS cp ON mc.company_id = cp.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
    AND k.keyword ILIKE '%action%'
ORDER BY 
    m.production_year DESC, 
    a.name;
