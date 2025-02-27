SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    COUNT(DISTINCT di.id) AS distinct_movie_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    complete_cast di ON t.id = di.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IS NOT NULL
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, c.kind, m.name, k.keyword, p.info
ORDER BY 
    distinct_movie_count DESC, t.title ASC;
