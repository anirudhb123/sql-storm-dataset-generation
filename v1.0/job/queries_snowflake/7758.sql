SELECT 
    ak.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    c.note AS cast_note,
    k.keyword AS movie_keyword, 
    m.info AS movie_info, 
    co.name AS company_name
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON ak.person_id = p.imdb_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year >= 2000 
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    ak.name;
