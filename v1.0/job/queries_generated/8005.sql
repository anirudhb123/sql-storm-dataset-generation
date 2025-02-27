SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS role_note,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_kinds,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    mi.info AS movie_info
FROM 
    title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
GROUP BY 
    t.title, a.name, ci.note, mi.info
ORDER BY 
    t.production_year DESC, a.name;
