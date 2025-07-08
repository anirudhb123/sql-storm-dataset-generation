SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    ct.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    mu.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info mu ON t.id = mu.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
    AND k.keyword IN ('Drama', 'Thriller')
ORDER BY 
    a.name, t.production_year DESC;
