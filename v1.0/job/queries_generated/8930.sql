SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    ct.kind AS role_type
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    person_info AS p ON a.person_id = p.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ct ON mc.company_type_id = ct.id
JOIN 
    keyword AS k ON t.id = k.id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%bio%')
ORDER BY 
    t.production_year DESC, a.name;
