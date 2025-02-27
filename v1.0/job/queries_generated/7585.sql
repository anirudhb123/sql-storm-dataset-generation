SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    c.kind AS company_type,
    p.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = m.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
    AND c.kind LIKE 'Production%'
GROUP BY 
    a.name, m.title, m.production_year, c.kind, p.info
ORDER BY 
    m.production_year DESC, a.name;
