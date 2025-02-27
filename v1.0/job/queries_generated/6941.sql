SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cc.kind AS comp_cast_type,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_keyword k ON t.id = k.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.imdb_index IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2022
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, a.name;
