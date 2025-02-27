SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.note AS role_note,
    m.production_year,
    k.keyword AS movie_keyword,
    tp.kind AS movie_type
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
    aka_name a ON c.person_id = a.person_id
JOIN 
    company_name cn ON t.id = cn.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type tp ON mc.company_type_id = tp.id
WHERE 
    m.production_year > 2000
ORDER BY 
    t.title, a.name;
