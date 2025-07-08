
SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords, 
    ct.kind AS company_type,
    p.info AS person_info
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
AND 
    k.keyword IS NOT NULL 
GROUP BY 
    t.title, a.name, ct.kind, p.info 
ORDER BY 
    t.title ASC, a.name ASC;
