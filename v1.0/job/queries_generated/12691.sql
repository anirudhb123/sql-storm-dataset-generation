SELECT 
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title,
    c.id AS cast_info_id,
    c.note AS cast_note,
    ci.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name ci ON mc.company_id = ci.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
