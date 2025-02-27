
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_biography,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    t.production_year,
    COUNT(DISTINCT co.name) AS company_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    ct.kind = 'Distributor'
GROUP BY 
    t.title, a.name, p.info, k.keyword, ct.kind, t.production_year
ORDER BY 
    t.production_year DESC, t.title;
