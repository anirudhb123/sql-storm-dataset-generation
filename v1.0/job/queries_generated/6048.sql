SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    g.kind AS genre,
    COUNT(DISTINCT r.role) AS role_count,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.name AS company_name,
    p.info AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    kind_type g ON m.kind_id = g.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
    AND g.kind = 'Drama'
GROUP BY 
    a.name, m.title, m.production_year, g.kind, c.name, p.info
ORDER BY 
    m.production_year DESC, actor_name ASC;
