SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    p.info AS actor_info,
    mk.keyword AS movie_keyword,
    cn.name AS company_name
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
    AND mk.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    t.title, 
    c.name;
