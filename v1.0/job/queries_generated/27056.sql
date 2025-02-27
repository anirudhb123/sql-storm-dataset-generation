SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Role Note' END) AS role_note,
    ci.nr_order AS role_order,
    c.kind AS company_type,
    cn.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 2000
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, ci.nr_order, ci.note, c.kind, cn.name
ORDER BY 
    t.production_year DESC, actor_name;
