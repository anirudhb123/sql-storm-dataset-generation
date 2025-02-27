SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ci.note AS role_note,
    m.info AS movie_info,
    c.kind AS comp_kind,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
AND 
    ci.note IS NOT NULL
GROUP BY 
    a.name, t.title, ci.note, m.info, c.kind
ORDER BY 
    keyword_count DESC, a.name ASC;
