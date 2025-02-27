
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    STRING_AGG(k.keyword, ', ') AS keywords,
    ct.kind AS company_type,
    p.info AS person_info
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND ci.note IS NULL
GROUP BY 
    t.title, a.name, ct.kind, p.info
ORDER BY 
    t.title, a.name;
