SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.note AS role_note,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
JOIN 
    aka_name n ON c.person_id = n.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    t.title;
