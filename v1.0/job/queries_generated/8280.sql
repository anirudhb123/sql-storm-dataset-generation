SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    m.name AS company_name,
    CASE 
        WHEN mi.info IS NOT NULL THEN mi.info 
        ELSE 'No additional info' 
    END AS movie_info,
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
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, m.name, mi.info
ORDER BY 
    keyword_count DESC, a.name ASC;
