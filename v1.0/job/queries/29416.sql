
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    pi.info AS person_info
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = 1 
WHERE 
    t.production_year >= 2000
    AND k.keyword LIKE '%action%' 
GROUP BY 
    t.title, a.name, pi.info, t.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    t.production_year DESC, a.name;
