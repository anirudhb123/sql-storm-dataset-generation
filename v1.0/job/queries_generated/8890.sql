SELECT 
    ka.title AS aka_title,
    m.title AS movie_title,
    c.nr_order,
    p.info AS person_info,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    r.role AS role_type,
    i.info AS movie_info
FROM 
    aka_title ka
JOIN 
    movie_link ml ON ka.movie_id = ml.movie_id
JOIN 
    title m ON ml.linked_movie_id = m.id
JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    cast_info c ON cc.id = c.movie_id
JOIN 
    name n ON c.person_id = n.imdb_id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    n.name, m.production_year DESC;
