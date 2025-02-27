SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    co.name AS company_name,
    m.production_year AS release_year,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT m.id) OVER (PARTITION BY a.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE 'A%' 
AND 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    a.name, m.production_year DESC;
