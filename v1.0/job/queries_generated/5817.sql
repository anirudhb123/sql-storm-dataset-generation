SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name, 
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name co ON cc.subject_id = co.imdb_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info ti ON t.id = ti.movie_id
WHERE 
    c.note IS NULL 
    AND t.production_year > 2000 
    AND k.keyword LIKE 'Action%'
ORDER BY 
    t.production_year DESC, 
    a.name;
