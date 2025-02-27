SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    m.info AS movie_info,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.country_code = 'USA'
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, m.info
ORDER BY 
    actor_name, movie_title;
