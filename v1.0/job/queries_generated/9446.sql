SELECT 
    ak.name AS aka_name,
    m.title AS movie_title,
    c.nr_order AS role_order,
    p.info AS person_info,
    cmp.name AS company_name,
    k.keyword AS movie_keyword,
    rt.role AS role_type
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cmp ON mc.company_id = cmp.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    m.production_year >= 2000
AND 
    ak.md5sum IS NOT NULL
ORDER BY 
    m.production_year DESC, c.nr_order ASC
LIMIT 100;
