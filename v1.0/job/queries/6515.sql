
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT i.info, ', ') AS movie_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    keyword_count DESC, t.production_year ASC;
