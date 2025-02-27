SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    ci.role_id AS actor_role
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    a.name ASC
LIMIT 100;
