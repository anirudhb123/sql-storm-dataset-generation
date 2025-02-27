
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    cm.name AS company_name,
    k.keyword AS keyword,
    t.production_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    cm.country_code = 'USA'
GROUP BY 
    t.title, cm.name, k.keyword, t.production_year
ORDER BY 
    t.production_year DESC, cast_count DESC;
