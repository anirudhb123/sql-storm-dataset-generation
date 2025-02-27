SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    co.name AS company_name,
    m.production_year,
    k.keyword AS movie_keyword,
    SUM(CASE WHEN a.name IS NOT NULL THEN 1 ELSE 0 END) AS actor_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON t.id = m.id
WHERE 
    m.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind, co.name, m.production_year, k.keyword
ORDER BY 
    actor_count DESC, m.production_year DESC
LIMIT 50;
