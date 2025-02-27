SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    person_info AS pi ON a.person_id = pi.person_id
JOIN 
    role_type AS rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
AND 
    c.kind LIKE 'Actor%'
ORDER BY 
    t.production_year DESC, 
    a.name;
