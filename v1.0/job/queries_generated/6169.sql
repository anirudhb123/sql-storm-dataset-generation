SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    c.kind AS cast_type,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    keyword ki ON t.id = (SELECT mk.movie_id FROM movie_keyword mk WHERE mk.keyword_id = ki.id)
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
    AND it.info = 'Box Office'
GROUP BY 
    a.name, t.title, p.info, c.kind, co.name, ki.keyword
ORDER BY 
    total_movies DESC
LIMIT 10;
