SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    co.name AS company_name,
    rn.info AS release_note,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
LEFT JOIN 
    movie_info_idx rn ON t.id = rn.movie_id AND rn.info_type_id = (SELECT id FROM info_type WHERE info = 'release note')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 1990 AND 2020
AND 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
