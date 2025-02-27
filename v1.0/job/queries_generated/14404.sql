SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ch.name AS character_name,
    co.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    char_name ch ON c.person_role_id = ch.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    t.production_year DESC, a.name;
