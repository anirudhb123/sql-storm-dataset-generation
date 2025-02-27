SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role_id,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ci.kind AS company_type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
WHERE 
    t.production_year >= 2000
    AND ci.kind LIKE '%Production%'
ORDER BY 
    t.title, a.name;