
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    pm.info AS personal_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info pm ON cc.subject_id = pm.person_id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, ct.kind, k.keyword, pm.info, t.production_year
ORDER BY 
    t.production_year DESC, 
    a.name;
