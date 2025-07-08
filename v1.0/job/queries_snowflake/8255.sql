SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    rt.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
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
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year >= 2000
    AND (m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%'))
    AND k.keyword IN ('Action', 'Drama')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
