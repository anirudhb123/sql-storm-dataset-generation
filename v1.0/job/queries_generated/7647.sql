SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
    AND ct.kind IN ('actor', 'actress')
    AND c.country_code = 'USA'
GROUP BY 
    t.title, ak.name, ct.kind, c.name, m.production_year
ORDER BY 
    t.production_year DESC, ak.name ASC;
