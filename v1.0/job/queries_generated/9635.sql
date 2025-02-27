SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    cc.kind AS cast_type,
    c.name AS company_name,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    c.country_code = 'USA'
    AND m.production_year >= 2000
GROUP BY 
    t.id, a.name, cc.kind, c.name, m.production_year
ORDER BY 
    m.production_year DESC, t.title;
