SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id AS role_id,
    cnt.name AS company_name,
    mt.kind AS company_type,
    k.keyword AS movie_keyword,
    ti.info AS movie_info,
    ct.kind AS character_type,
    p.info AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cnt ON mc.company_id = cnt.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    char_name cn ON ak.id = cn.id
JOIN 
    role_type ct ON c.role_id = ct.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND cnt.country_code = 'USA'
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
ORDER BY 
    t.production_year DESC, ak.name;
