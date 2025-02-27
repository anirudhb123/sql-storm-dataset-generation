SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    COUNT(DISTINCT m.id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
AND 
    t.production_year >= 2000
AND 
    co.country_code = 'USA'
AND 
    it.info LIKE '%Oscar%'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    movie_count DESC, actor_name ASC
LIMIT 10;
