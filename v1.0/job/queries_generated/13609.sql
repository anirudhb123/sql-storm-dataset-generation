SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.gender AS person_gender,
    k.keyword AS movie_keyword,
    ci.kind AS cast_info_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    a.name, t.title;
