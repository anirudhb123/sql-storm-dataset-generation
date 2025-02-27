SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    m.info AS movie_info,
    COUNT(k.keyword) AS keyword_count
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
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name ILIKE 'J%'
    AND t.production_year BETWEEN 2000 AND 2020
    AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    a.name, t.title, c.kind, co.name, m.info
ORDER BY 
    keyword_count DESC, a.name;
