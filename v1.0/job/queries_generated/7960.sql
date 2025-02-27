SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    COUNT(k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT i.info, ', ') AS additional_info,
    COUNT(DISTINCT p.id) AS unique_people_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, actor_name ASC;
