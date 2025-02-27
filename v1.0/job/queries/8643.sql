
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    c.name AS company_name,
    ct.kind AS company_type,
    pi.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    (t.production_year BETWEEN 2000 AND 2023) 
    AND (c.country_code = 'USA')
GROUP BY 
    t.title, a.name, c.name, ct.kind, pi.info
ORDER BY 
    MAX(t.production_year) DESC, a.name ASC;
