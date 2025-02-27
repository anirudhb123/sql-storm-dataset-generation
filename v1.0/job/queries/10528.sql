SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.nr_order AS cast_order,
    c.name AS character_name,
    com.name AS company_name,
    k.keyword AS movie_keyword,
    m.production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    char_name c ON t.id = c.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON t.movie_id = m.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    t.title;
