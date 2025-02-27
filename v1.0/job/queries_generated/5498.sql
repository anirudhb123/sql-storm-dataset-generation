SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    c.name AS company_name,
    ty.kind AS company_type,
    pi.info AS person_info
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ty ON mc.company_type_id = ty.id
JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND k.keyword ILIKE '%action%'
GROUP BY 
    t.title, ak.name, c.name, ty.kind, pi.info
ORDER BY 
    t.production_year DESC, ak.name;
