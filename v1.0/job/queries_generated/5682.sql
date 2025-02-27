SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    i.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT co.name) AS total_companies
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
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind, i.info, k.keyword
ORDER BY 
    total_companies DESC, a.name;
