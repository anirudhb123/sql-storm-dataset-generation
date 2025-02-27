SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(GROUP_CONCAT(DISTINCT cn.name), 'No companies') AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
AND 
    m.note IS NULL
AND 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_movies DESC, a.name;
