
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ct.kind AS company_type,
    COUNT(DISTINCT p.id) AS total_person_info,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON cn.id = mc.company_id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    ct.kind LIKE 'Production%'
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, a.name, ct.kind
ORDER BY 
    total_person_info DESC, cast_count DESC;
