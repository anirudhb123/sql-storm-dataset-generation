SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS character_note,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mi.info) AS movie_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, ci.note
ORDER BY 
    a.name, t.title;
