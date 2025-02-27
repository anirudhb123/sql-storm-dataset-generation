SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ci.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info i ON t.movie_id = i.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2000
ORDER BY 
    t.production_year DESC, a.name;
