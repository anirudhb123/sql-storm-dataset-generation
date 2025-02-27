
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    STRING_AGG(DISTINCT cn.name, ',') AS companies,
    COUNT(DISTINCT c.id) AS cast_count,
    rt.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, t.production_year, rt.role
ORDER BY 
    t.production_year DESC, actor_name;
