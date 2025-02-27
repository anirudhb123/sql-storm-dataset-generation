SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    c.nr_order AS role_order,
    p.info AS person_info,
    tt.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    keyword k ON k.id IN (SELECT movie_keyword.keyword_id FROM movie_keyword WHERE movie_keyword.movie_id = t.id)
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
    AND cn.country_code = 'USA'
ORDER BY 
    tt.production_year DESC, a.name;
