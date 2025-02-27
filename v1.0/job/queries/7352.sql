
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mi.id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    aka_title t ON t.id = ci.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind, t.production_year
ORDER BY 
    t.production_year DESC, a.name ASC;
