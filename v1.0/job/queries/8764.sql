SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    t.production_year, 
    p.info AS person_info, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    company_name cn ON t.id = cn.imdb_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id AND mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    c.kind = 'Production'
ORDER BY 
    t.production_year DESC, 
    a.name;
