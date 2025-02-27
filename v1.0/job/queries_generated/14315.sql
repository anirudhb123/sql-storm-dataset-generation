SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_title,
    c.note AS cast_note,
    m.production_year,
    g.kind AS genre,
    k.keyword AS movie_keyword
FROM 
    title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.id
JOIN 
    aka_name AS a ON c.person_id = a.person_id
JOIN 
    role_type AS r ON c.role_id = r.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    kind_type AS g ON t.kind_id = g.id
ORDER BY 
    m.production_year DESC, t.title;
