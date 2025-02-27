SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    p.info AS person_info,
    cn.name AS character_name
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON cc.subject_id = p.person_id
JOIN 
    char_name cn ON p.person_id = cn.imdb_id
WHERE 
    t.production_year > 2000
    AND k.keyword LIKE '%action%'
    AND c.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
