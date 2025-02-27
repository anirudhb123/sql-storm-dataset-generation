SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    c.kind AS cast_type,
    GROUP_CONCAT(k.keyword) AS keywords,
    COUNT(DISTINCT m.id) AS production_companies,
    AVG(mi.info LIKE '%budget%') AS average_budget_flag
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies m ON t.id = m.movie_id
JOIN 
    company_type ct ON m.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, p.name, c.kind
ORDER BY 
    t.production_year DESC, p.name;
