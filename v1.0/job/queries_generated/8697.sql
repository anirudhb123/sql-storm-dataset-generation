SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS actor_role,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    role_type AS r ON ci.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info AS i ON t.id = i.movie_id
WHERE 
    t.production_year >= 2000 AND 
    c.country_code = 'USA' AND 
    k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
