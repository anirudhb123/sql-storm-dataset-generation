SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    ct.kind AS cast_type,
    ci.info AS company_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name cn ON ci.movie_id = cn.imdb_id
JOIN 
    company_type ct ON cn.id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    char_name c ON ci.movie_id = c.imdb_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
