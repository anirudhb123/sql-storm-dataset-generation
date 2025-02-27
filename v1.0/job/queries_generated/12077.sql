SELECT 
    t.title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.note AS cast_note,
    m.info AS movie_info,
    kt.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
