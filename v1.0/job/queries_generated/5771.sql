SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.nr_order AS cast_order,
    ct.kind AS company_type,
    COUNT(mk.keyword) AS keyword_count,
    MIN(mi.info) AS first_info,
    MAX(mi.info) AS last_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND ct.kind IS NOT NULL
GROUP BY 
    t.title, p.name, c.nr_order, ct.kind
ORDER BY 
    movie_title, person_name;
