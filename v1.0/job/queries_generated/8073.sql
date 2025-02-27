SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    tc.kind AS company_type,
    co.name AS company_name,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count
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
    company_type tc ON mc.company_type_id = tc.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    ci.nr_order = 1 
GROUP BY 
    a.name, t.title, c.kind, tc.kind, co.name, m.production_year
ORDER BY 
    keyword_count DESC, t.production_year ASC;
