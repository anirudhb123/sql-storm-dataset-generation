SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.info AS movie_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT ci.info) AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year > 2000
    AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'BoxOffice')
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    t.production_year DESC, actor_name ASC;
