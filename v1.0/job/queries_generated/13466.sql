SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ch.name AS character_name,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    char_name ch ON c.role_id = ch.id
JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON m.movie_id = c.movie_id
WHERE 
    t.production_year >= 2000
AND 
    k.keyword IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
