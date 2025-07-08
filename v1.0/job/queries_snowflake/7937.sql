SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    ct.kind AS cast_type,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    t.production_year AS release_year
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND ct.kind IN ('Actor', 'Actress')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
