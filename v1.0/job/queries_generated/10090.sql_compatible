
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    m.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    info_type it ON m.info_type_id = it.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, ct.kind, m.info, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
