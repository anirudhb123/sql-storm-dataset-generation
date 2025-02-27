SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    co.name AS company_name,
    m.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    kind_type c ON t.kind_id = c.id
WHERE 
    m.production_year >= 2000
    AND c.kind = 'Lead'
GROUP BY 
    a.name, t.title, c.kind, co.name, m.production_year
ORDER BY 
    keyword_count DESC, m.production_year DESC;
