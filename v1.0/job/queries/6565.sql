
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    m.production_year,
    k.keyword AS movie_keyword,
    COUNT(c.id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON t.movie_id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, m.production_year, ct.kind, k.keyword
ORDER BY 
    cast_count DESC, m.production_year DESC;
