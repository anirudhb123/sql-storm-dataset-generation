SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    cp.kind AS company_type,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword k ON t.id = k.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    a.name, t.production_year DESC;
