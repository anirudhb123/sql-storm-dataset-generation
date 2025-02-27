SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    pt.role AS person_role, 
    ci.kind AS company_type, 
    k.keyword AS movie_keyword, 
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type pt ON c.role_id = pt.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, c.nr_order, pt.role, ci.kind
ORDER BY 
    total_movies DESC, a.name ASC;
