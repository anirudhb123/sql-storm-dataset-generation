SELECT 
    a.name AS actress_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    ct.kind AS company_type,
    COUNT(DISTINCT k.keyword) AS keyword_count
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
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND ct.kind LIKE '%Production%'
GROUP BY 
    a.name, t.title, c.nr_order, ct.kind
ORDER BY 
    keyword_count DESC, a.name, t.title;
