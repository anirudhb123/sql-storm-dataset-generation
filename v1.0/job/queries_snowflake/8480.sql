SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    ti.info AS movie_info,
    k.keyword AS movie_keyword,
    MAX(t.production_year) AS latest_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    company_name c ON t.id = (SELECT mc.movie_id FROM movie_companies mc WHERE mc.company_id = c.id LIMIT 1)
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    t.production_year >= 2000
AND 
    ti.info LIKE '%box office%'
GROUP BY 
    t.title, a.name, ct.kind, c.name, ti.info, k.keyword
ORDER BY 
    latest_year DESC, movie_title ASC
LIMIT 100;
