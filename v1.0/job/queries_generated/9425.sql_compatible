
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS person_info,
    COUNT(mc.movie_id) AS total_companies,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    ct.kind AS company_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 AND
    ct.kind = 'Production'
GROUP BY 
    t.title, a.name, p.info, ct.kind
HAVING 
    COUNT(mc.movie_id) > 5
ORDER BY 
    total_companies DESC, movie_title ASC;
