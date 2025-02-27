SELECT 
    p.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    kt.keyword AS movie_keyword,
    ka.name AS aka_name
FROM 
    cast_info c
JOIN 
    aka_name ka ON c.person_id = ka.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
    AND ka.imdb_index IS NOT NULL
ORDER BY 
    t.production_year DESC, actor_name, movie_title;
