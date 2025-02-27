SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS cast_role,
    co.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, c.kind, co.name, ct.kind
ORDER BY 
    t.production_year DESC, a.name;
