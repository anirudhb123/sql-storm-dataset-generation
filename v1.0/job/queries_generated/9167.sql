SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    p.info AS actor_info,
    c.kind AS company_type,
    COUNT(k.keyword) AS keyword_count,
    MAX(m.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name LIKE 'John%'
AND 
    p.info_type_id IN (SELECT id FROM info_type WHERE info = 'biography')
GROUP BY 
    a.name, t.title, p.info, c.kind
ORDER BY 
    keyword_count DESC, latest_movie_year DESC;
