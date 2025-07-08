SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id AS cast_role,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cp.kind AS company_type,
    m.info AS movie_info,
    n.name AS person_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    name n ON a.person_id = n.imdb_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND cp.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, a.name;