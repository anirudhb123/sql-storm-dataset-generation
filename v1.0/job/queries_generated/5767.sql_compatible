
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT kw.keyword, ',') AS keywords,
    COUNT(DISTINCT pi.info) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000 
    AND ct.kind = 'Distributor'
GROUP BY 
    a.name, t.title, c.nr_order, ct.kind
HAVING 
    COUNT(DISTINCT pi.info) > 0
ORDER BY 
    a.name, t.title;
