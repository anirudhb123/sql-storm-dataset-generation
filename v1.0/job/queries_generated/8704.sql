SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ti.info AS movie_info,
    COUNT(DISTINCT mc.movie_id) AS total_movies
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword ILIKE '%action%'
GROUP BY 
    t.title, a.name, p.info, c.kind, k.keyword, co.name, ti.info
ORDER BY 
    total_movies DESC, a.name;
