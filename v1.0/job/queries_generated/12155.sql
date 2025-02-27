SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.gender AS person_gender,
    c.kind AS role_kind,
    k.keyword AS movie_keyword,
    ci.note AS cast_info_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type k ON t.kind_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    name p ON a.person_id = p.imdb_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
